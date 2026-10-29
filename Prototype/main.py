"""
Protótipo de linha de comando - SCC0640 - Sistema de Gestão de Eventos e Espaços.

Fluxo:
  1. lê os parâmetros de conexão do config.json (e permite alterá-los);
  2. extrai o DDL do Projeto.txt (usado como contexto do esquema para o modelo);
  3. conecta ao PostgreSQL e cria o cliente do Ollama;
  4. menu: executar as 5 consultas do projeto ou fazer uma pergunta em
     linguagem natural, que o modelo converte para SQL.

Execução: python main.py
"""

import getpass
import json
import re
from pathlib import Path

import psycopg
from ollama import Client, ResponseError

BASE_DIR = Path(__file__).resolve().parent

# Máximo de linhas mostradas na tela para um resultado.
LIMITE_EXIBICAO = 50

# As 5 consultas do projeto: idênticas à seção "4. CONSULTAS" do Projeto.txt.
CONSULTAS = [
    {
        "objetivo": "Listar a programação da Semana da Computação 2026 (atividade, tipo, data, horário e espaço de cada sessão) em ordem cronológica.",
        "sql": """SELECT a.activity_title, a.activity_category, s.session_date, s.start_time, s.end_time, sp.space_name, s.requires_registration
FROM event e
JOIN activity a ON a.event_id = e.event_id
JOIN session s ON s.activity_id = a.activity_id
JOIN space sp ON sp.space_id = s.space_id
WHERE e.event_name = 'Semana da Computação 2026'
ORDER BY s.session_date, s.start_time;""",
    },
    {
        "objetivo": "Mostrar as sessões com inscrição que já preencheram pelo menos metade das vagas, com confirmados, limite efetivo e vagas restantes.",
        "sql": """SELECT e.event_name, a.activity_title, s.session_id, s.session_date,
       COUNT(sa.person_id) AS confirmados,
       COALESCE(s.max_vacancies, sp.space_capacity) AS limite,
       COALESCE(s.max_vacancies, sp.space_capacity) - COUNT(sa.person_id) AS vagas_restantes
FROM session s
JOIN activity a ON a.activity_id = s.activity_id
JOIN event e ON e.event_id = a.event_id
JOIN space sp ON sp.space_id = s.space_id
JOIN session_attendee sa ON sa.session_id = s.session_id
WHERE s.requires_registration = true
  AND sa.registration_status = 'confirmed'
GROUP BY e.event_name, a.activity_title, s.session_id, s.session_date, s.max_vacancies, sp.space_capacity
HAVING COUNT(sa.person_id) >= 0.5 * COALESCE(s.max_vacancies, sp.space_capacity)
ORDER BY vagas_restantes, s.session_id;""",
    },
    {
        "objetivo": "Listar os participantes confirmados no evento 3 (Semana da Computação 2026) que estão confirmados em todas as sessões com inscrição desse evento.",
        "sql": """SELECT p.person_id, p.person_name
FROM person p
JOIN event_attendee ea ON ea.person_id = p.person_id
WHERE ea.event_id = 3
  AND ea.registration_status = 'confirmed'
  AND NOT EXISTS (
      SELECT 1
      FROM session s
      JOIN activity a ON a.activity_id = s.activity_id
      WHERE a.event_id = 3
        AND s.requires_registration = true
        AND NOT EXISTS (
            SELECT 1
            FROM session_attendee sa
            WHERE sa.session_id = s.session_id
              AND sa.person_id = p.person_id
              AND sa.registration_status = 'confirmed'
        )
  )
ORDER BY p.person_name;""",
    },
    {
        "objetivo": "Comparar o número de inscritos confirmados entre as edições de cada série, com ranking dentro da série e diferença em relação à edição anterior.",
        "sql": """WITH inscritos_por_edicao AS (
    SELECT es.series_name, e.edition_number, e.event_name,
           COUNT(ea.person_id) AS inscritos
    FROM event_series es
    JOIN event e ON e.series_id = es.series_id
    LEFT JOIN event_attendee ea ON ea.event_id = e.event_id
                               AND ea.registration_status = 'confirmed'
    GROUP BY es.series_name, e.edition_number, e.event_name
)
SELECT series_name, edition_number, event_name, inscritos,
       RANK() OVER (PARTITION BY series_name ORDER BY inscritos DESC) AS ranking_na_serie,
       inscritos - LAG(inscritos) OVER (PARTITION BY series_name ORDER BY edition_number) AS diferenca_edicao_anterior
FROM inscritos_por_edicao
ORDER BY series_name, edition_number;""",
    },
    {
        "objetivo": "Listar todos os espaços com a quantidade de sessões e o custo total dos recursos instalados, incluindo espaços sem nenhuma sessão.",
        "sql": """SELECT sp.space_name, sp.space_category, sp.space_capacity,
       COUNT(s.session_id) AS total_sessoes,
       COALESCE(custos.custo_recursos, 0) AS custo_recursos
FROM space sp
LEFT JOIN session s ON s.space_id = sp.space_id
LEFT JOIN (
    SELECT sr.space_id, SUM(sr.quantity * r.unit_cost) AS custo_recursos
    FROM space_resource sr
    JOIN resource r ON r.resource_id = sr.resource_id
    GROUP BY sr.space_id
) custos ON custos.space_id = sp.space_id
GROUP BY sp.space_id, sp.space_name, sp.space_category, sp.space_capacity, custos.custo_recursos
ORDER BY total_sessoes DESC, sp.space_name;""",
    },
]

# Valores válidos das colunas com CHECK. Os dados estão em inglês, então o
# modelo precisa saber exatamente quais valores usar nos filtros.
VALORES_PERMITIDOS = """- event.event_category: 'technology', 'art & culture', 'science', 'business', 'entertainment', 'music'
- activity.activity_category: 'lecture', 'workshop', 'short_course', 'panel', 'round_table', 'presentation'
- space.space_category: 'classroom', 'auditorium', 'laboratory', 'exhibition_hall', 'meeting_room', 'outdoor_area', 'virtual_room'
- event_attendee.registration_status e session_attendee.registration_status: 'confirmed', 'cancelled'
- person.gender: 'Male', 'Female', 'Non-binary', 'Prefer not to disclose'
- address.address_type: 'residential', 'event'"""


def carregar_config():
    """Lê o config.json que fica na mesma pasta do main.py."""
    try:
        with open(BASE_DIR / "config.json", encoding="utf-8") as f:
            config = json.load(f)
    except (OSError, json.JSONDecodeError) as erro:
        print(f"Erro ao ler config.json: {erro}")
        raise SystemExit(1)
    return config


def confirmar_parametros_conexao(config):
    """Mostra os parâmetros do banco (sem a senha) e permite alterá-los."""
    db = config["database"]
    print("\nParâmetros de conexão lidos do config.json:")
    print(f"  host:   {db['host']}")
    print(f"  port:   {db['port']}")
    print(f"  dbname: {db['dbname']}")
    print(f"  user:   {db['user']}")

    resposta = input("Usar estes parâmetros? [S/n]: ").strip().lower()
    if resposta in ("", "s", "sim"):
        return config

    print("Digite os novos valores (Enter mantém o valor atual).")
    for chave in ("host", "port", "dbname", "user"):
        valor = input(f"  {chave} [{db[chave]}]: ").strip()
        if valor:
            db[chave] = valor
    senha = getpass.getpass("  password [Enter mantém a atual]: ")
    if senha:
        db["password"] = senha
    return config


def carregar_ddl():
    """Extrai a seção de DDL do Projeto.txt (pasta acima do Prototipo)."""
    projeto_path = BASE_DIR.parent / "Projeto.txt"
    if not projeto_path.exists():
        print("Erro: Projeto.txt não encontrado.")
        raise SystemExit(1)
    projeto = projeto_path.read_text(encoding="utf-8")
    try:
        ddl = projeto.split("3. DDL COMPLETO", 1)[1]
        ddl = ddl.split("4. CONSULTAS", 1)[0]
        ddl = ddl.strip()
    except IndexError:
        print("Erro: seções '3. DDL COMPLETO' e '4. CONSULTAS' não encontradas no Projeto.txt.")
        raise SystemExit(1)

    # Remove as linhas separadoras do template (compostas só por '=').
    linhas = [linha for linha in ddl.splitlines() if not re.fullmatch(r"=+", linha.strip())]
    return "\n".join(linhas).strip()


def esquema_para_modelo(ddl):
    """Resume o DDL em uma linha por tabela (colunas, PK e FKs).

    O DDL completo (com comentários, CHECKs e triggers) é grande demais para a
    janela de contexto padrão do Ollama; o resumo mantém o que o modelo precisa
    para montar um SELECT. Os valores dos CHECKs vão em VALORES_PERMITIDOS.
    """
    tipos = r"(bigint|integer|numeric|text|varchar|date|timestamptz|time|interval|boolean)"
    resumo = []
    for tabela, corpo in re.findall(r"CREATE TABLE (\w+)\s*\((.*?)\n\);", ddl, flags=re.DOTALL):
        corpo = re.sub(r"--[^\n]*", "", corpo)  # remove comentários
        colunas = re.findall(r"^\s*(\w+) " + tipos, corpo, flags=re.MULTILINE)
        chave = re.search(r"PRIMARY KEY\s*\(([^)]*)\)", corpo).group(1)
        fks = re.findall(r"FOREIGN KEY\s*\((\w+)\)\s*REFERENCES (\w+)\((\w+)\)", corpo)

        linha = f"{tabela}(" + ", ".join(f"{nome} {tipo}" for nome, tipo in colunas) + ")"
        linha += f" PK({chave})"
        for coluna, tabela_ref, coluna_ref in fks:
            linha += f" FK({coluna} -> {tabela_ref}.{coluna_ref})"
        resumo.append(linha)
    return "\n".join(resumo)


def conectar_banco(config):
    """Abre a conexão com o PostgreSQL em modo somente leitura."""
    db = config["database"]
    conn = psycopg.connect(
        host=db["host"],
        port=db["port"],
        dbname=db["dbname"],
        user=db["user"],
        password=db["password"]
    )
    # Proteção: nenhuma transação desta conexão pode alterar dados.
    conn.read_only = True
    return conn


def criar_cliente_ollama(config):
    """Cria o cliente do Ollama com o host do config.json."""
    ollama_config = config["ollama"]
    client = Client(
        host=ollama_config["host"]
    )
    return client


def executar_sql(conn, sql):
    """Executa uma consulta e exibe o resultado; em caso de erro mostra a mensagem."""
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            if cur.description is None:
                print("O comando não retornou resultados.")
                conn.rollback()
                return
            colunas = [coluna.name for coluna in cur.description]
            linhas = cur.fetchall()
        conn.commit()
    except psycopg.Error as erro:
        print(f"\nErro ao executar a consulta: {erro}")
        if not conn.closed:
            conn.rollback()
        return
    exibir_resultado(colunas, linhas)


def formatar_valor(valor):
    """Converte um valor do banco em texto para a tabela (NULL para None)."""
    if valor is None:
        return "NULL"
    return str(valor)


def exibir_resultado(colunas, linhas):
    """Imprime o resultado como tabela de texto alinhada."""
    if not linhas:
        print("\nNenhum resultado encontrado.")
        return

    exibidas = [[formatar_valor(v) for v in linha] for linha in linhas[:LIMITE_EXIBICAO]]

    # Largura de cada coluna = maior texto entre o nome e os valores.
    larguras = [len(nome) for nome in colunas]
    for linha in exibidas:
        for i, texto in enumerate(linha):
            larguras[i] = max(larguras[i], len(texto))

    print()
    print(" | ".join(nome.ljust(larguras[i]) for i, nome in enumerate(colunas)))
    print("-+-".join("-" * largura for largura in larguras))
    for linha in exibidas:
        print(" | ".join(texto.ljust(larguras[i]) for i, texto in enumerate(linha)))

    print(f"\n({len(linhas)} linha(s))")
    if len(linhas) > LIMITE_EXIBICAO:
        print(f"Exibindo apenas as primeiras {LIMITE_EXIBICAO} linhas.")


def menu_consultas(conn):
    """Lista as 5 consultas do projeto e executa a escolhida."""
    while True:
        print("\nCONSULTAS DO PROJETO")
        for i, consulta in enumerate(CONSULTAS, start=1):
            print(f"  {i} - {consulta['objetivo']}")
        print("  0 - Voltar")
        opcao = input("Escolha: ").strip()

        if opcao == "0":
            return
        if opcao.isdigit() and 1 <= int(opcao) <= len(CONSULTAS):
            consulta = CONSULTAS[int(opcao) - 1]
            print(f"\nOBJETIVO: {consulta['objetivo']}")
            print(f"SQL:\n{consulta['sql']}")
            executar_sql(conn, consulta["sql"])
        else:
            print("Opção inválida.")


def montar_prompt(esquema, pergunta):
    """Monta o texto enviado ao modelo com o esquema, as regras e a pergunta."""
    return f"""Você é um assistente que converte perguntas em consultas SQL para PostgreSQL.

Esquema do banco (DDL):
{esquema}

Valores válidos de categorias e status (os dados estão em inglês):
{VALORES_PERMITIDOS}

Observações:
- Nomes de eventos, pessoas, atividades e espaços estão em português (ex.: 'Semana da Computação 2026').
- Para comparar textos de nomes, prefira ILIKE com '%'.
- Inscrições só contam quando registration_status = 'confirmed'.

Regras da resposta:
- Retorne APENAS uma consulta SELECT válida em PostgreSQL (pode começar com WITH).
- Use somente tabelas e colunas que existem no esquema acima.
- Não escreva explicações, comentários nem blocos de markdown.

Pergunta: {pergunta}
/no_think"""


def limpar_sql_gerado(resposta):
    """Remove o raciocínio <think>, as cercas de markdown, textos extras e espaços."""
    texto = re.sub(r"<think>.*?</think>", "", resposta, flags=re.DOTALL)
    texto = re.sub(r"```(?:sql)?", "", texto, flags=re.IGNORECASE)

    # Se o modelo escreveu alguma frase antes da consulta, começa no primeiro
    # SELECT/WITH; se escreveu algo depois, corta no primeiro ';'.
    inicio = re.search(r"\b(SELECT|WITH)\b", texto)
    if inicio:
        texto = texto[inicio.start():]
    if ";" in texto:
        texto = texto[:texto.index(";") + 1]
    return texto.strip()


def validar_somente_leitura(sql):
    """Retorna uma mensagem de erro, ou None se o SQL for um único SELECT/WITH."""
    comando = sql.strip().rstrip(";").strip()
    if not comando:
        return "O modelo não retornou nenhuma consulta."
    primeira_palavra = comando.split(None, 1)[0].upper()
    if primeira_palavra not in ("SELECT", "WITH"):
        return "Apenas consultas iniciadas por SELECT ou WITH são permitidas."
    if ";" in comando:
        return "A resposta contém mais de um comando SQL."
    return None


def pergunta_linguagem_natural(conn, client, config, esquema):
    """Recebe uma pergunta, gera o SQL com o Ollama, valida e executa."""
    pergunta = input("\nDigite sua pergunta (Enter para voltar): ").strip()
    if not pergunta:
        return

    prompt = montar_prompt(esquema, pergunta)
    ollama_config = config["ollama"]
    print("Consultando o modelo, aguarde...")
    try:
        response = client.chat(
            model=ollama_config["model"],
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )
        resposta = response["message"]["content"]
    except ResponseError as erro:
        print(f"Erro retornado pelo Ollama: {erro.error}")
        return
    except Exception as erro:  # ex.: servidor do Ollama desligado
        print(f"Não foi possível conectar ao Ollama: {erro}")
        return

    sql = limpar_sql_gerado(resposta)
    print(f"\nSQL gerado:\n{sql}")

    erro = validar_somente_leitura(sql)
    if erro:
        print(f"Consulta rejeitada: {erro}")
        return
    executar_sql(conn, sql)


def main():
    """Ponto de entrada: configuração, conexões e menu principal."""
    config = carregar_config()
    config = confirmar_parametros_conexao(config)
    ddl = carregar_ddl()
    esquema = esquema_para_modelo(ddl)

    try:
        conn = conectar_banco(config)
    except psycopg.Error as erro:
        print(f"Não foi possível conectar ao PostgreSQL: {erro}")
        raise SystemExit(1)
    print("Conectado ao PostgreSQL.")

    client = criar_cliente_ollama(config)

    try:
        while True:
            print("\nMENU PRINCIPAL")
            print("  1 - Consultas do projeto")
            print("  2 - Pergunta em linguagem natural")
            print("  0 - Sair")
            opcao = input("Escolha: ").strip()

            if opcao == "1":
                menu_consultas(conn)
            elif opcao == "2":
                pergunta_linguagem_natural(conn, client, config, esquema)
            elif opcao == "0":
                break
            else:
                print("Opção inválida.")
    except (KeyboardInterrupt, EOFError):
        print()
    finally:
        conn.close()
    print("Até logo!")


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print("\nAté logo!")
