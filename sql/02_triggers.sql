-- ------------------------------------------------------------
-- FUNÇÕES E TRIGGERS
-- ------------------------------------------------------------


-- TRIGGER 1 - Capacidade total do evento
-- Tabela: event_attendee | Evento: INSERT ou UPDATE | Momento: BEFORE
-- Por que BEFORE: a inscrição deve ser rejeitada antes de ser gravada.
-- Dados examinados: event.event_capacity e as inscrições confirmadas
-- do mesmo evento.
-- Ação: só verifica inscrições 'confirmed'. Conta os confirmados do
-- evento, excluindo a própria linha no UPDATE (senão ela seria contada
-- duas vezes), e rejeita se a capacidade já foi atingida.
CREATE OR REPLACE FUNCTION fn_event_total_capacity_constraint()
RETURNS trigger AS $$
DECLARE
	v_event_capacity integer;
	v_confirmed integer;
BEGIN
	-- Inscrição cancelada não ocupa vaga.
	IF NEW.registration_status <> 'confirmed' THEN
		RETURN NEW;
	END IF;

	SELECT event_capacity INTO v_event_capacity
	FROM event
	WHERE event_id = NEW.event_id;

	SELECT count(*) INTO v_confirmed
	FROM event_attendee
	WHERE event_id = NEW.event_id
		AND registration_status = 'confirmed'
		-- No UPDATE, a linha antiga não entra na contagem.
		AND NOT (TG_OP = 'UPDATE'
			AND event_id = OLD.event_id
			AND person_id = OLD.person_id);

	IF v_confirmed >= v_event_capacity THEN
		RAISE EXCEPTION 'Evento lotado: capacidade de % inscritos atingida.', v_event_capacity;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_event_total_capacity_constraint
BEFORE INSERT OR UPDATE ON event_attendee
FOR EACH ROW
EXECUTE FUNCTION fn_event_total_capacity_constraint();


-- TRIGGER 2 - Conflito de espaço entre sessões
-- Tabela: session | Evento: INSERT ou UPDATE de espaço, data ou horário
-- Momento: BEFORE, para impedir que a sessão conflitante seja gravada.
-- Dados examinados: outras sessões no mesmo espaço e na mesma data.
-- Ação: rejeita se os intervalos de horário se sobrepõem (OVERLAPS).
-- Intervalos apenas encostados (ex.: 9h-12h e 12h-14h) não conflitam.
CREATE OR REPLACE FUNCTION fn_same_instant_sessions_constraint()
RETURNS trigger AS $$
BEGIN
	PERFORM 1
	FROM session
	WHERE space_id = NEW.space_id
		AND session_date = NEW.session_date
		AND (NEW.start_time, NEW.end_time) OVERLAPS (start_time, end_time)
		-- Ignora a própria sessão (caso de UPDATE).
		AND session_id <> NEW.session_id;

	IF FOUND THEN
		RAISE EXCEPTION 'Conflito de espaço: já existe sessão neste espaço, data e horário.';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_same_instant_sessions_constraint
BEFORE INSERT OR UPDATE OF space_id, session_date, start_time, end_time ON session
FOR EACH ROW
EXECUTE FUNCTION fn_same_instant_sessions_constraint();


-- TRIGGER 3 - Inscrição em sessão e controle de vagas
-- Tabela: session_attendee | Evento: INSERT ou UPDATE | Momento: BEFORE
-- Por que BEFORE: a inscrição inválida não pode chegar a ser gravada.
-- Dados examinados: session (exige inscrição? limite próprio), space
-- (capacidade), activity (evento da sessão), event_attendee (pessoa
-- confirmada no evento) e as inscrições confirmadas da sessão.
-- Ação: rejeita se a sessão não exige inscrição; para inscrição
-- confirmada, rejeita se a pessoa não está confirmada no evento ou se
-- o limite COALESCE(max_vacancies, space_capacity) foi atingido.
CREATE OR REPLACE FUNCTION fn_session_registration_constraint()
RETURNS trigger AS $$
DECLARE
	v_requires_registration boolean;
	v_event_id bigint;
	v_limit integer;
	v_confirmed integer;
BEGIN
	SELECT s.requires_registration,
		a.event_id,
		COALESCE(s.max_vacancies, sp.space_capacity)
	INTO v_requires_registration, v_event_id, v_limit
	FROM session s
	JOIN activity a ON a.activity_id = s.activity_id
	JOIN space sp ON sp.space_id = s.space_id
	WHERE s.session_id = NEW.session_id;

	IF NOT v_requires_registration THEN
		RAISE EXCEPTION 'Esta sessão não exige inscrição: basta a inscrição no evento.';
	END IF;

	-- Cancelamento não ocupa vaga e não precisa das demais verificações.
	IF NEW.registration_status <> 'confirmed' THEN
		RETURN NEW;
	END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM event_attendee
		WHERE event_id = v_event_id
			AND person_id = NEW.person_id
			AND registration_status = 'confirmed'
	) THEN
		RAISE EXCEPTION 'A pessoa precisa estar confirmada no evento para se inscrever na sessão.';
	END IF;

	SELECT count(*) INTO v_confirmed
	FROM session_attendee
	WHERE session_id = NEW.session_id
		AND registration_status = 'confirmed'
		-- No UPDATE, a linha antiga não entra na contagem.
		AND NOT (TG_OP = 'UPDATE'
			AND session_id = OLD.session_id
			AND person_id = OLD.person_id);

	IF v_confirmed >= v_limit THEN
		RAISE EXCEPTION 'Sessão lotada: limite de % vagas atingido.', v_limit;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_session_registration_constraint
BEFORE INSERT OR UPDATE ON session_attendee
FOR EACH ROW
EXECUTE FUNCTION fn_session_registration_constraint();


-- TRIGGER 4 - Histórico de alterações de sessão
-- Tabela: session | Evento: UPDATE | Momento: AFTER
-- Por que AFTER: só registra a mudança depois que ela passou por todas
-- as validações (triggers BEFORE e constraints) e foi de fato aplicada.
-- Dados examinados: valores OLD e NEW de espaço, data e horários.
-- Ação: grava os valores antigos em session_history. A cláusula WHEN
-- faz o trigger disparar só quando algum desses campos mudou de fato
-- (IS DISTINCT FROM também trata NULL corretamente).
CREATE OR REPLACE FUNCTION fn_session_history_log()
RETURNS trigger AS $$
BEGIN
	INSERT INTO session_history
		(session_id, old_space_id, old_session_date, old_start_time, old_end_time)
	VALUES
		(OLD.session_id, OLD.space_id, OLD.session_date, OLD.start_time, OLD.end_time);

	RETURN NULL; -- em trigger AFTER o valor de retorno é ignorado
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_session_history_log
AFTER UPDATE ON session
FOR EACH ROW
WHEN (OLD.space_id IS DISTINCT FROM NEW.space_id
	OR OLD.session_date IS DISTINCT FROM NEW.session_date
	OR OLD.start_time IS DISTINCT FROM NEW.start_time
	OR OLD.end_time IS DISTINCT FROM NEW.end_time)
EXECUTE FUNCTION fn_session_history_log();


-- TRIGGER 5 - Coerência da sessão com o evento e o espaço
-- Tabela: session | Evento: INSERT ou UPDATE | Momento: BEFORE
-- Por que BEFORE: impede gravar uma sessão incoerente.
-- Dados examinados: período do evento (via activity) e capacidade do
-- espaço escolhido.
-- Ação: rejeita se session_date está fora do período do evento ou se
-- max_vacancies é maior que a capacidade do espaço.
CREATE OR REPLACE FUNCTION fn_session_consistency_constraint()
RETURNS trigger AS $$
DECLARE
	v_start_date date;
	v_end_date date;
	v_space_capacity integer;
BEGIN
	SELECT e.start_date, e.end_date INTO v_start_date, v_end_date
	FROM activity a
	JOIN event e ON e.event_id = a.event_id
	WHERE a.activity_id = NEW.activity_id;

	IF NEW.session_date NOT BETWEEN v_start_date AND v_end_date THEN
		RAISE EXCEPTION 'Data da sessão (%) fora do período do evento (% a %).',
			NEW.session_date, v_start_date, v_end_date;
	END IF;

	SELECT space_capacity INTO v_space_capacity
	FROM space
	WHERE space_id = NEW.space_id;

	IF NEW.max_vacancies > v_space_capacity THEN
		RAISE EXCEPTION 'Vagas da sessão (%) excedem a capacidade do espaço (%).',
			NEW.max_vacancies, v_space_capacity;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_session_consistency_constraint
BEFORE INSERT OR UPDATE ON session
FOR EACH ROW
EXECUTE FUNCTION fn_session_consistency_constraint();
