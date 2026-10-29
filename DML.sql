-- ------------------------------------------------------------
-- DML - Sistema de Gestão de Eventos e Espaços
-- Executar logo após o DDL, em banco vazio.
-- Os IDs são GENERATED ALWAYS e começam em 1, na ordem de inserção.
-- Os comentários indicam o ID de cada registro.
-- ------------------------------------------------------------


-- ADDRESS
-- 1-2: locais de evento | 3-14: residências
-- (3 e 4 têm o mesmo CEP: CEP não é único)
INSERT INTO address (cep, street, address_number, neighborhood, city, address_state, complement, address_type, address_capacity) VALUES
('13566590', 'Avenida Trabalhador São-carlense', '400', 'Parque Arnold Schimidt', 'São Carlos', 'SP', 'ICMC - USP', 'event', 2000),   -- 1
('13092150', 'Avenida Guilherme Campos', '500', 'Jardim Santa Genebra', 'Campinas', 'SP', 'Pavilhão B', 'event', 1500),               -- 2
('13560001', 'Rua Episcopal', '1200', 'Centro', 'São Carlos', 'SP', 'Apto 12', 'residential', NULL),                                    -- 3
('13560001', 'Rua Episcopal', '1350', 'Centro', 'São Carlos', 'SP', NULL, 'residential', NULL),                                         -- 4
('13560250', 'Rua Dona Alexandrina', '850', 'Centro', 'São Carlos', 'SP', NULL, 'residential', NULL),                                   -- 5
('13566100', 'Avenida São Carlos', '2500', 'Vila Nery', 'São Carlos', 'SP', 'Casa 2', 'residential', NULL),                             -- 6
('14801320', 'Rua São Bento', '700', 'Centro', 'Araraquara', 'SP', NULL, 'residential', NULL),                                          -- 7
('14802500', 'Avenida Bento de Abreu', '1500', 'Vila Xavier', 'Araraquara', 'SP', NULL, 'residential', NULL),                           -- 8
('13083970', 'Rua Sérgio Buarque de Holanda', '100', 'Cidade Universitária', 'Campinas', 'SP', 'Bloco C', 'residential', NULL),         -- 9
('13010100', 'Rua Barão de Jaguara', '900', 'Centro', 'Campinas', 'SP', NULL, 'residential', NULL),                                     -- 10
('01310100', 'Avenida Paulista', '1000', 'Bela Vista', 'São Paulo', 'SP', 'Apto 81', 'residential', NULL),                              -- 11
('05509000', 'Rua Alvarenga', '1500', 'Butantã', 'São Paulo', 'SP', NULL, 'residential', NULL),                                         -- 12
('14010100', 'Rua General Osório', '500', 'Centro', 'Ribeirão Preto', 'SP', NULL, 'residential', NULL),                                 -- 13
('14020260', 'Avenida Presidente Vargas', '2000', 'Jardim América', 'Ribeirão Preto', 'SP', 'Apto 303', 'residential', NULL);          -- 14


-- LEGAL_ENTITY
INSERT INTO legal_entity (cnpj, entity_name, contact_email) VALUES
('63025530000104', 'Instituto de Ciências Matemáticas e de Computação - USP', 'eventos@icmc.usp.br'),  -- 1
('12345678000190', 'TechNova Software Ltda', 'contato@technova.com.br'),                                -- 2
('23456789000101', 'Associação Paulista de Ciência de Dados', 'secretaria@apcd.org.br'),                -- 3
('34567890000112', 'Banco Horizonte S.A.', 'patrocinios@bancohorizonte.com.br');                       -- 4


-- PERSON
-- 1-5: organizadores | 6-15: palestrantes | 16-20: staff | 21-40: participantes
-- Papéis sobrepostos: 2 (organizador e participante), 3 (organizador e
-- palestrante), 6 e 7 (palestrantes e participantes), 16 (staff e participante).
INSERT INTO person (cpf, birth_date, person_name, gender, email, occupation, address_id) VALUES
('31245678901', '1978-03-12', 'Ana Paula Ferreira', 'Female', 'ana.ferreira@usp.br', 'Professora', 3),                  -- 1
('42356789012', '1985-07-25', 'Carlos Eduardo Lima', 'Male', 'carlos.lima@usp.br', 'Professor', 4),                     -- 2
('53467890123', '1982-11-02', 'Mariana Souza Rocha', 'Female', 'mariana.rocha@usp.br', 'Professora', 5),                -- 3
('64578901234', '1990-01-18', 'Ricardo Almeida Nunes', 'Male', 'ricardo.nunes@apcd.org.br', 'Analista de Dados', 6),    -- 4
('75689012345', '1988-05-30', 'Juliana Costa Martins', 'Female', 'juliana.martins@email.com', 'Produtora de Eventos', 7), -- 5
('86790123456', '1987-09-14', 'Fernando Oliveira Santos', 'Male', 'fernando.santos@email.com', 'Engenheiro de Software', 8), -- 6
('97801234567', '1995-12-08', 'Beatriz Ramos Carvalho', 'Female', 'beatriz.carvalho@usp.br', 'Doutoranda', 9),          -- 7
('18912345678', '1980-04-21', 'Gustavo Henrique Pereira', 'Male', 'gustavo.pereira@email.com', 'DBA', 10),             -- 8
('29023456789', '1991-06-03', 'Larissa Mendes Barbosa', 'Female', 'larissa.barbosa@email.com', 'Cientista de Dados', 11), -- 9
('30134567890', '1984-10-27', 'Rafael Teixeira Gomes', 'Male', 'rafael.gomes@technova.com.br', 'Pesquisador em IA', 12), -- 10
('41245678902', '1993-02-16', 'Camila Ribeiro Dias', 'Female', 'camila.dias@email.com', 'Engenheira DevOps', 13),       -- 11
('52356789013', '1979-08-09', 'Thiago Moreira Castro', 'Male', 'thiago.castro@email.com', 'Estatístico', 14),           -- 12
('63467890124', '1986-12-24', 'Patrícia Azevedo Cardoso', 'Female', 'patricia.cardoso@email.com', 'Gerente de Produto', 3), -- 13
('74578901235', '1992-03-05', 'Lucas Fernandes Araújo', 'Male', 'lucas.araujo@email.com', 'Desenvolvedor Web', 4),      -- 14
('85689012346', '1989-07-19', 'Renata Cavalcanti Melo', 'Female', 'renata.melo@email.com', 'Empreendedora', 5),         -- 15
('96790123457', '1998-11-11', 'Diego Martins Rocha', 'Male', 'diego.rocha@usp.br', 'Técnico de TI', 6),                 -- 16
('17801234568', '1997-01-28', 'Aline Correia Pinto', 'Female', 'aline.pinto@email.com', 'Recepcionista', 7),            -- 17
('28912345679', '1996-04-07', 'Bruno Nascimento Freitas', 'Male', 'bruno.freitas@email.com', 'Técnico de Áudio', 8),    -- 18
('39023456780', '1999-09-22', 'Vanessa Lopes Moura', 'Female', 'vanessa.moura@email.com', 'Estudante', 9),              -- 19
('40134567891', '2000-06-15', 'Felipe Barros Monteiro', 'Male', 'felipe.monteiro@email.com', 'Estudante', 10),          -- 20
('51245678903', '2002-02-10', 'Gabriela Santos Vieira', 'Female', 'gabriela.vieira@usp.br', 'Estudante', 11),           -- 21
('62356789014', '2001-05-23', 'Leonardo Rodrigues Cunha', 'Male', 'leonardo.cunha@usp.br', 'Estudante', 12),            -- 22
('73467890125', '2003-08-30', 'Isabela Farias Duarte', 'Female', 'isabela.duarte@usp.br', 'Estudante', 13),             -- 23
('84578901236', '2002-12-01', 'Mateus Cardoso Ribeiro', 'Male', 'mateus.ribeiro@usp.br', 'Estudante', 14),              -- 24
('95689012347', '2001-03-17', 'Letícia Nogueira Batista', 'Female', 'leticia.batista@email.com', 'Estudante', 3),       -- 25
('16790123458', '2000-10-04', 'Pedro Henrique Campos', 'Male', 'pedro.campos@email.com', 'Estagiário', 4),              -- 26
('27801234569', '1999-07-12', 'Amanda Pires Siqueira', 'Female', 'amanda.siqueira@email.com', 'Analista Júnior', 5),    -- 27
('38912345670', '2003-01-26', 'João Victor Tavares', 'Male', 'joao.tavares@usp.br', 'Estudante', 6),                    -- 28
('49023456781', '2002-04-18', 'Natália Freire Andrade', 'Female', 'natalia.andrade@email.com', 'Estudante', 7),         -- 29
('50134567892', '1998-09-09', 'Gabriel Antunes Moraes', 'Male', 'gabriel.moraes@email.com', 'Desenvolvedor', 8),        -- 30
('61245678904', '2001-11-29', 'Sofia Rezende Lacerda', 'Non-binary', 'sofia.lacerda@email.com', 'Designer', 9),          -- 31
('72356789015', '1997-06-06', 'Vinícius Prado Fonseca', 'Male', 'vinicius.fonseca@email.com', 'Analista de BI', 10),    -- 32
('83467890126', '2000-02-14', 'Laura Macedo Brandão', 'Female', 'laura.brandao@email.com', 'Estudante', 11),            -- 33
('94578901237', '1995-05-05', 'Henrique Assis Toledo', 'Male', 'henrique.toledo@email.com', 'Consultor', 12),           -- 34
('15689012348', '1996-08-20', 'Carolina Peixoto Lima', 'Female', 'carolina.lima@email.com', 'Engenheira', 13),          -- 35
('26790123459', '1994-12-13', 'Eduardo Vasconcelos Reis', 'Male', 'eduardo.reis@email.com', 'Empresário', 14),          -- 36
('37801234560', '2002-03-03', 'Yasmin Coelho Arruda', 'Female', 'yasmin.arruda@email.com', 'Estudante', 3),             -- 37
('48912345671', '1993-10-31', 'Rodrigo Sales Bezerra', 'Prefer not to disclose', 'rodrigo.bezerra@email.com', 'Investidor', 4), -- 38
('59023456782', '1999-01-07', 'Manuela Guerra Pacheco', 'Female', 'manuela.pacheco@email.com', 'Estudante', 5),         -- 39
('60134567893', '1991-04-25', 'Daniel Queiroz Matos', 'Male', 'daniel.matos@email.com', 'Gerente de TI', 6);            -- 40


-- ESPECIALIZAÇÕES (papéis sobrepostos)

-- ORGANIZER: pessoas 1 a 5
INSERT INTO organizer (person_id) VALUES (1), (2), (3), (4), (5);

-- SPEAKER: pessoas 3 e 6 a 15
INSERT INTO speaker (person_id, mini_bio) VALUES
(3,  'Professora do ICMC, pesquisa computação e sociedade.'),
(6,  'Engenheiro de software com 15 anos de experiência em sistemas distribuídos.'),
(7,  'Doutoranda em ciência da computação, área de aprendizado de máquina.'),
(8,  'DBA especialista em PostgreSQL e otimização de consultas.'),
(9,  'Cientista de dados e instrutora de Python.'),
(10, 'Pesquisador em inteligência artificial generativa.'),
(11, 'Engenheira DevOps, mantenedora de projetos open source.'),
(12, 'Estatístico com atuação em mercado financeiro.'),
(13, 'Gerente de produto em empresa de tecnologia.'),
(14, 'Desenvolvedor web full stack.'),
(15, 'Fundadora de duas startups de tecnologia.');

-- STAFF: pessoas 16 a 20
INSERT INTO staff (person_id, role_description) VALUES
(16, 'Suporte técnico'),
(17, 'Credenciamento'),
(18, 'Áudio e vídeo'),
(19, 'Monitoria de salas'),
(20, 'Monitoria de salas');

-- ATTENDEE: pessoas 2, 6, 7, 16 e 21 a 40
INSERT INTO attendee (person_id, institution) VALUES
(2,  'USP'), (6,  NULL), (7,  'USP'), (16, 'USP'),
(21, 'USP'), (22, 'USP'), (23, 'USP'), (24, 'USP'), (25, 'UFSCar'),
(26, 'UFSCar'), (27, NULL), (28, 'USP'), (29, 'UNESP'), (30, NULL),
(31, 'UNICAMP'), (32, NULL), (33, 'UNICAMP'), (34, NULL), (35, NULL),
(36, NULL), (37, 'UNICAMP'), (38, NULL), (39, 'PUC-Campinas'), (40, NULL);


-- EVENT_SERIES
INSERT INTO event_series (series_name, description) VALUES
('Semana da Computação', 'Semana acadêmica anual do ICMC com palestras, minicursos e workshops.'),      -- 1
('Simpósio Paulista de Ciência de Dados', 'Simpósio sobre estatística, aprendizado de máquina e ética em dados.'), -- 2
('Feira de Inovação e Negócios', 'Feira de startups, empreendedorismo e investimento em tecnologia.');            -- 3


-- EVENT
-- Série 1 tem 3 edições (eventos 1, 2 e 3).
-- Evento 4 é promovido só por entidade; evento 5 só por pessoa (Q1).
INSERT INTO event (series_id, edition_number, start_date, end_date, event_name, event_category, event_capacity, address_id, hosting_entity_id, primary_organizer_id) VALUES
(1, 1, '2024-09-16', '2024-09-20', 'Semana da Computação 2024', 'technology', 120, 1, 1, 1),         -- 1
(1, 2, '2025-09-15', '2025-09-19', 'Semana da Computação 2025', 'technology', 150, 1, 1, 1),         -- 2
(1, 3, '2026-09-14', '2026-09-18', 'Semana da Computação 2026', 'technology', 200, 1, 1, 2),         -- 3
(2, 1, '2026-05-11', '2026-05-13', 'Simpósio Paulista de Ciência de Dados 2026', 'science', 80, 2, 3, NULL), -- 4
(3, 1, '2026-08-04', '2026-08-06', 'Feira de Inovação e Negócios 2026', 'business', 10, 2, NULL, 3); -- 5


-- EVENT_ORGANIZER (demais organizadores, além do principal)
INSERT INTO event_organizer (event_id, person_id) VALUES
(1, 4), (2, 5), (3, 1), (3, 3), (4, 4), (4, 5), (5, 2);

-- EVENT_SPONSOR
INSERT INTO event_sponsor (event_id, legal_entity_id, sponsorship_value) VALUES
(1, 2, 5000.00),
(2, 2, 8000.00), (2, 4, 10000.00),
(3, 2, 10000.00), (3, 3, 3000.00), (3, 4, 15000.00),
(4, 2, 6000.00),
(5, 4, 20000.00), (5, 2, 7500.00);

-- EVENT_STAFF
INSERT INTO event_staff (event_id, person_id) VALUES
(1, 16), (1, 17),
(2, 16), (2, 18),
(3, 16), (3, 17), (3, 19), (3, 20),
(4, 18), (4, 19),
(5, 20);


-- SPACE
-- Os espaços 6, 8 e 12 não recebem sessões (aparecem na consulta 5).
INSERT INTO space (space_name, space_capacity, space_category) VALUES
('Auditório Fernão Stella', 300, 'auditorium'),            -- 1
('Sala 1-001', 60, 'classroom'),                           -- 2
('Sala 1-002', 40, 'classroom'),                           -- 3
('Laboratório LCC 1', 30, 'laboratory'),                   -- 4
('Laboratório LCC 2', 25, 'laboratory'),                   -- 5
('Sala de Reuniões ICMC', 15, 'meeting_room'),             -- 6
('Saguão de Exposições ICMC', 200, 'exhibition_hall'),     -- 7
('Área Verde Central', 150, 'outdoor_area'),               -- 8
('Sala Virtual 1', 500, 'virtual_room'),                   -- 9
('Auditório do Centro de Convenções', 250, 'auditorium'),  -- 10
('Sala Workshop A', 35, 'classroom'),                      -- 11
('Sala Workshop B', 20, 'meeting_room');                   -- 12


-- RESOURCE
INSERT INTO resource (resource_name, unit_cost) VALUES
('Projetor', 150.00),               -- 1
('Computador', 300.00),             -- 2
('Sistema de áudio', 200.00),       -- 3
('Microfone sem fio', 50.00),       -- 4
('Acesso à Internet (Wi-Fi)', 80.00), -- 5
('Lousa digital', 120.00),          -- 6
('Câmera de transmissão', 250.00),  -- 7
('Cadeira extra', 10.00);           -- 8


-- SPACE_RESOURCE (o espaço 6 não tem recursos)
INSERT INTO space_resource (space_id, resource_id, quantity) VALUES
(1, 1, 2), (1, 3, 1), (1, 4, 4), (1, 5, 1), (1, 7, 1),
(2, 1, 1), (2, 5, 1), (2, 6, 1),
(3, 1, 1), (3, 5, 1),
(4, 1, 1), (4, 2, 30), (4, 5, 1),
(5, 1, 1), (5, 2, 25), (5, 5, 1),
(7, 3, 1), (7, 5, 1), (7, 8, 50),
(8, 3, 1), (8, 8, 100),
(9, 5, 1), (9, 7, 2),
(10, 1, 2), (10, 3, 1), (10, 4, 6), (10, 7, 2),
(11, 1, 1), (11, 2, 20), (11, 5, 1),
(12, 1, 1), (12, 6, 1);


-- EVENT_SPACE (espaços disponibilizados para cada evento)
INSERT INTO event_space (event_id, space_id) VALUES
(1, 1), (1, 2), (1, 4),
(2, 1), (2, 4), (2, 5), (2, 9),
(3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 7), (3, 9),
(4, 9), (4, 10), (4, 11),
(5, 9), (5, 10), (5, 11);


-- ACTIVITY
INSERT INTO activity (activity_title, description, activity_category, event_id) VALUES
-- Evento 1
('Palestra de Abertura: O Futuro da Computação', 'Panorama das tendências da computação.', 'lecture', 1),           -- 1
('Workshop de PostgreSQL', 'Modelagem, SQL e triggers na prática.', 'workshop', 1),                                 -- 2
('Minicurso de Python', 'Introdução à linguagem Python.', 'short_course', 1),                                       -- 3
-- Evento 2
('Palestra: Inteligência Artificial Generativa', 'Modelos de linguagem e suas aplicações.', 'lecture', 2),          -- 4
('Workshop de Git e GitHub', 'Versionamento de código em equipe.', 'workshop', 2),                                  -- 5
('Mesa-redonda: Carreira em Tecnologia', 'Profissionais discutem trajetórias na área.', 'round_table', 2),          -- 6
('Minicurso de Desenvolvimento Web', 'HTML, CSS e JavaScript em três encontros.', 'short_course', 2),               -- 7
-- Evento 3
('Palestra de Abertura: Computação e Sociedade', 'Impactos sociais da computação.', 'lecture', 3),                  -- 8
('Workshop de PostgreSQL Avançado', 'Funções de janela, CTEs e otimização.', 'workshop', 3),                        -- 9
('Minicurso Introdução a Python', 'Primeiros passos em Python.', 'short_course', 3),                                -- 10
('Painel: Mulheres na Computação', 'Debate sobre diversidade na área.', 'panel', 3),                                -- 11
('Workshop de Docker', 'Contêineres para desenvolvimento e implantação.', 'workshop', 3),                           -- 12
('Apresentação de Projetos de Iniciação Científica', 'Alunos apresentam seus projetos.', 'presentation', 3),        -- 13
-- Evento 4
('Palestra: Estatística para Ciência de Dados', 'Fundamentos estatísticos essenciais.', 'lecture', 4),              -- 14
('Workshop de Machine Learning com scikit-learn', 'Classificação e regressão na prática.', 'workshop', 4),          -- 15
('Painel: Ética em Dados', 'Privacidade, viés e LGPD.', 'panel', 4),                                                -- 16
('Minicurso de Visualização de Dados', 'Gráficos eficazes com Python.', 'short_course', 4),                         -- 17
-- Evento 5
('Palestra: Empreendedorismo em Tecnologia', 'Como transformar uma ideia em negócio.', 'lecture', 5),               -- 18
('Painel: Investimento-anjo e Startups', 'Investidores e fundadores conversam.', 'panel', 5),                       -- 19
('Apresentação de Startups', 'Startups apresentam seus produtos a investidores.', 'presentation', 5);               -- 20


-- ACTIVITY_SPEAKER (a pessoa 3 é organizadora e palestrante)
INSERT INTO activity_speaker (activity_id, person_id) VALUES
(1, 3), (2, 8), (3, 9),
(4, 10), (5, 11), (6, 6), (6, 12), (6, 13), (7, 14),
(8, 3), (9, 8), (10, 9), (10, 7), (11, 11), (11, 13), (11, 15), (12, 14), (13, 15),
(14, 12), (15, 10), (16, 6), (16, 13), (17, 9),
(18, 15), (19, 12), (19, 14), (20, 6);


-- SESSION
-- requires_registration = true indica sessão com inscrição adicional.
-- max_vacancies NULL significa que o limite é a capacidade do espaço.
INSERT INTO session (activity_id, space_id, session_date, start_time, end_time, requires_registration, max_vacancies) VALUES
-- Evento 1 (16 a 20/09/2024)
(1, 1, '2024-09-16', '09:00', '10:30', false, NULL),  -- 1
(2, 4, '2024-09-17', '09:00', '12:00', true, 20),     -- 2
(2, 4, '2024-09-17', '14:00', '17:00', true, 20),     -- 3
(3, 2, '2024-09-18', '09:00', '12:00', true, NULL),   -- 4
(3, 2, '2024-09-19', '09:00', '12:00', true, NULL),   -- 5
-- Evento 2 (15 a 19/09/2025)
(4, 1, '2025-09-15', '09:00', '10:30', false, NULL),  -- 6
(4, 9, '2025-09-16', '19:00', '20:30', false, NULL),  -- 7
(5, 5, '2025-09-16', '09:00', '12:00', true, 10),     -- 8
(5, 5, '2025-09-16', '14:00', '17:00', true, 10),     -- 9
(6, 1, '2025-09-17', '14:00', '16:00', false, NULL),  -- 10
(7, 4, '2025-09-17', '09:00', '12:00', true, 15),     -- 11
(7, 4, '2025-09-18', '09:00', '12:00', true, 15),     -- 12
(7, 4, '2025-09-19', '09:00', '12:00', true, 15),     -- 13
-- Evento 3 (14 a 18/09/2026)
(8, 1, '2026-09-14', '09:00', '10:30', false, NULL),  -- 14
(9, 4, '2026-09-14', '14:00', '17:00', true, 5),      -- 15
(9, 5, '2026-09-15', '14:00', '17:00', true, 5),      -- 16
(10, 2, '2026-09-15', '09:00', '12:00', true, 8),     -- 17
(10, 3, '2026-09-16', '09:00', '12:00', true, 8),     -- 18
(11, 1, '2026-09-16', '14:00', '16:00', false, NULL), -- 19
(12, 5, '2026-09-17', '09:00', '12:00', true, 6),     -- 20
(12, 5, '2026-09-17', '14:00', '17:00', true, 6),     -- 21
(13, 7, '2026-09-18', '10:00', '16:00', false, NULL), -- 22
(11, 9, '2026-09-16', '19:00', '21:00', false, NULL), -- 23
-- Evento 4 (11 a 13/05/2026)
(14, 10, '2026-05-11', '09:00', '10:30', false, NULL), -- 24
(15, 11, '2026-05-11', '14:00', '17:00', true, 12),    -- 25
(15, 11, '2026-05-12', '14:00', '17:00', true, 12),    -- 26
(16, 10, '2026-05-12', '09:00', '11:00', false, NULL), -- 27
(17, 11, '2026-05-13', '09:00', '12:00', true, 4),     -- 28
(17, 9, '2026-05-13', '14:00', '17:00', true, NULL),   -- 29
-- Evento 5 (04 a 06/08/2026)
(18, 10, '2026-08-04', '09:00', '10:30', false, NULL), -- 30
(19, 10, '2026-08-05', '10:00', '12:00', false, NULL), -- 31
(20, 10, '2026-08-06', '09:00', '12:00', false, NULL), -- 32
(20, 11, '2026-08-06', '14:00', '16:00', true, 8),     -- 33
(18, 9, '2026-08-04', '19:00', '20:30', false, NULL),  -- 34
(19, 11, '2026-08-05', '14:00', '16:00', true, 6);     -- 35


-- EVENT_ATTENDEE
-- registration_status usa o DEFAULT 'confirmed' quando omitido.
-- Evento 1: 21 a 28 confirmados; 29 cancelado.
INSERT INTO event_attendee (event_id, person_id) VALUES
(1, 21), (1, 22), (1, 23), (1, 24), (1, 25), (1, 26), (1, 27), (1, 28);
INSERT INTO event_attendee (event_id, person_id, registration_status) VALUES
(1, 29, 'cancelled');

-- Evento 2: 21 a 30, 6 e 16 confirmados; 31 cancelado.
INSERT INTO event_attendee (event_id, person_id) VALUES
(2, 21), (2, 22), (2, 23), (2, 24), (2, 25), (2, 26), (2, 27), (2, 28),
(2, 29), (2, 30), (2, 6), (2, 16);
INSERT INTO event_attendee (event_id, person_id, registration_status) VALUES
(2, 31, 'cancelled');

-- Evento 3: 21 a 35, 2 e 7 confirmados; 36 cancelado.
INSERT INTO event_attendee (event_id, person_id) VALUES
(3, 21), (3, 22), (3, 23), (3, 24), (3, 25), (3, 26), (3, 27), (3, 28),
(3, 29), (3, 30), (3, 31), (3, 32), (3, 33), (3, 34), (3, 35), (3, 2), (3, 7);
INSERT INTO event_attendee (event_id, person_id, registration_status) VALUES
(3, 36, 'cancelled');

-- Evento 4: 12 confirmados.
INSERT INTO event_attendee (event_id, person_id) VALUES
(4, 24), (4, 26), (4, 28), (4, 30), (4, 32), (4, 34),
(4, 36), (4, 37), (4, 38), (4, 39), (4, 40), (4, 6);

-- Evento 5 (capacidade 10): 30 a 39 confirmados, evento LOTADO.
-- A inscrição cancelada de 40 é aceita porque não ocupa vaga.
INSERT INTO event_attendee (event_id, person_id) VALUES
(5, 30), (5, 31), (5, 32), (5, 33), (5, 34),
(5, 35), (5, 36), (5, 37), (5, 38), (5, 39);
INSERT INTO event_attendee (event_id, person_id, registration_status) VALUES
(5, 40, 'cancelled');


-- SESSION_ATTENDEE (somente sessões com requires_registration = true)
INSERT INTO session_attendee (session_id, person_id) VALUES
-- Evento 1
(2, 21), (2, 22), (2, 23), (2, 24),
(3, 25), (3, 26),
(4, 21), (4, 23), (4, 25), (4, 27), (4, 28),
(5, 22), (5, 24), (5, 26),
-- Evento 2 (sessão 8 LOTADA: 10 de 10)
(8, 21), (8, 22), (8, 23), (8, 24), (8, 25), (8, 26), (8, 27), (8, 28), (8, 29), (8, 30),
(9, 6), (9, 16),
(11, 21), (11, 23), (11, 25),
(12, 21), (12, 23),
(13, 21), (13, 23), (13, 27),
-- Evento 3 (sessões 15, 17 e 20 LOTADAS)
-- 21 e 22 se inscrevem em todas as sessões com inscrição (consulta 3).
(15, 21), (15, 22), (15, 23), (15, 24), (15, 25),
(16, 21), (16, 22), (16, 23), (16, 26), (16, 27),
(17, 21), (17, 22), (17, 23), (17, 28), (17, 29), (17, 30), (17, 31), (17, 2),
(18, 21), (18, 22), (18, 32), (18, 33),
(20, 21), (20, 22), (20, 23), (20, 34), (20, 35), (20, 7),
(21, 21), (21, 22), (21, 23), (21, 24), (21, 25),
-- Evento 4 (sessão 28 LOTADA: 4 de 4)
(25, 24), (25, 26), (25, 28), (25, 30), (25, 6),
(26, 32), (26, 34), (26, 36),
(28, 24), (28, 26), (28, 37), (28, 38),
(29, 39), (29, 40), (29, 28),
-- Evento 5 (sessão 35 LOTADA: 6 de 6)
(33, 30), (33, 31), (33, 32), (33, 33), (33, 34), (33, 35),
(35, 36), (35, 37), (35, 38), (35, 39), (35, 30), (35, 31);


-- CANCELAMENTOS (UPDATE de inscrições já existentes)
UPDATE session_attendee SET registration_status = 'cancelled'
WHERE session_id = 16 AND person_id = 27;

UPDATE session_attendee SET registration_status = 'cancelled'
WHERE session_id = 21 AND person_id = 23;


-- ALTERAÇÕES DE PROGRAMAÇÃO (populam session_history via trigger)
-- Sessão 22: muda do saguão (7) para o auditório (1).
UPDATE session SET space_id = 1 WHERE session_id = 22;

-- Sessão 22 de novo: muda o horário (segunda linha de histórico).
UPDATE session SET start_time = '13:00', end_time = '17:00' WHERE session_id = 22;

-- Sessão 19: painel adiado em duas horas.
UPDATE session SET start_time = '16:00', end_time = '18:00' WHERE session_id = 19;

-- Sessão 26: workshop transferido para o dia seguinte.
UPDATE session SET session_date = '2026-05-13' WHERE session_id = 26;

-- Sessão 18: muda só o número de vagas, então NÃO gera histórico.
UPDATE session SET max_vacancies = 10 WHERE session_id = 18;
