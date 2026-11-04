-- ------------------------------------------------------------
-- TESTES DOS TRIGGERS
-- Executar depois do DDL e do DML.sql, por exemplo:
--   psql -d eventos -f sql/testes_triggers.sql
--
-- Casos que FUNCIONAM ficam entre BEGIN e ROLLBACK, para não alterar
-- os dados do DML. Casos que FALHAM ficam fora de transação: o erro é
-- exibido e nada é gravado. O erro esperado está anotado acima de cada um.
-- ------------------------------------------------------------


-- TRIGGER 1 - Capacidade do evento (event_attendee)

-- Funciona: evento 1 (capacidade 120) tem só 8 confirmados.
BEGIN;
INSERT INTO event_attendee (event_id, person_id) VALUES (1, 30);
-- Funciona: o evento 5 está lotado (10 de 10), mas atualizar uma
-- inscrição confirmada não conta a própria linha duas vezes.
UPDATE event_attendee SET registration_date = CURRENT_TIMESTAMP
WHERE event_id = 5 AND person_id = 30;
-- Funciona: inscrição cancelada não ocupa vaga, mesmo com evento lotado.
INSERT INTO event_attendee (event_id, person_id, registration_status) VALUES (5, 21, 'cancelled');
ROLLBACK;

-- Falha: evento 5 lotado.
-- ERRO ESPERADO: Evento lotado: capacidade de 10 inscritos atingida.
INSERT INTO event_attendee (event_id, person_id) VALUES (5, 21);

-- Falha: reativar a inscrição cancelada da pessoa 40 no evento 5 lotado.
-- ERRO ESPERADO: Evento lotado: capacidade de 10 inscritos atingida.
UPDATE event_attendee SET registration_status = 'confirmed'
WHERE event_id = 5 AND person_id = 40;


-- TRIGGER 2 - Conflito de espaço (session)

-- Funciona: 10:30-12:00 apenas encosta na sessão 14 (09:00-10:30) no
-- auditório 1; OVERLAPS não considera intervalos encostados.
BEGIN;
INSERT INTO session (activity_id, space_id, session_date, start_time, end_time)
VALUES (8, 1, '2026-09-14', '10:30', '12:00');
ROLLBACK;

-- Falha: 10:00-11:00 sobrepõe a sessão 14 no mesmo espaço e data.
-- ERRO ESPERADO: Conflito de espaço: já existe sessão neste espaço, data e horário.
INSERT INTO session (activity_id, space_id, session_date, start_time, end_time)
VALUES (8, 1, '2026-09-14', '10:00', '11:00');

-- Falha: mover a sessão 21 para o horário da sessão 20 (mesmo laboratório).
-- ERRO ESPERADO: Conflito de espaço: já existe sessão neste espaço, data e horário.
UPDATE session SET start_time = '10:00', end_time = '13:00' WHERE session_id = 21;


-- TRIGGER 3 - Inscrição em sessão (session_attendee)

-- Funciona: sessão 18 exige inscrição, tem vagas e a pessoa 23 está
-- confirmada no evento 3.
BEGIN;
INSERT INTO session_attendee (session_id, person_id) VALUES (18, 23);
-- Funciona: a sessão 15 está lotada (5 de 5), mas o UPDATE de uma
-- inscrição já confirmada não conta a própria linha duas vezes.
UPDATE session_attendee SET registration_date = CURRENT_TIMESTAMP
WHERE session_id = 15 AND person_id = 21;
ROLLBACK;

-- Falha: a sessão 14 (palestra de abertura) não exige inscrição.
-- ERRO ESPERADO: Esta sessão não exige inscrição: basta a inscrição no evento.
INSERT INTO session_attendee (session_id, person_id) VALUES (14, 21);

-- Falha: a pessoa 36 cancelou a inscrição no evento 3.
-- ERRO ESPERADO: A pessoa precisa estar confirmada no evento para se inscrever na sessão.
INSERT INTO session_attendee (session_id, person_id) VALUES (18, 36);

-- Falha: a sessão 15 está lotada (limite max_vacancies = 5).
-- ERRO ESPERADO: Sessão lotada: limite de 5 vagas atingido.
INSERT INTO session_attendee (session_id, person_id) VALUES (15, 26);


-- TRIGGER 4 - Histórico de sessão (session -> session_history)

-- Funciona: mudar o horário gera 1 linha em session_history com os
-- valores antigos (09:00-10:30).
BEGIN;
UPDATE session SET start_time = '10:00', end_time = '11:30' WHERE session_id = 24;
SELECT * FROM session_history WHERE session_id = 24;
-- Mudar só max_vacancies NÃO gera histórico (cláusula WHEN do trigger).
UPDATE session SET max_vacancies = 100 WHERE session_id = 24;
SELECT count(*) AS linhas_historico_sessao_24 FROM session_history WHERE session_id = 24; -- esperado: 1
ROLLBACK;

-- Este trigger não rejeita operações. Se a alteração for barrada por
-- outro trigger BEFORE, nada é registrado (o UPDATE nem acontece).
-- ERRO ESPERADO: Conflito de espaço: já existe sessão neste espaço, data e horário.
UPDATE session SET space_id = 4, session_date = '2026-09-14', start_time = '14:00', end_time = '15:00'
WHERE session_id = 18;


-- TRIGGER 5 - Coerência da sessão (session)

-- Funciona: data dentro do período do evento 4 e sem limite próprio.
BEGIN;
INSERT INTO session (activity_id, space_id, session_date, start_time, end_time)
VALUES (14, 10, '2026-05-13', '09:00', '10:00');
ROLLBACK;

-- Falha: o evento 4 vai de 11 a 13/05/2026.
-- ERRO ESPERADO: Data da sessão (2026-06-01) fora do período do evento (2026-05-11 a 2026-05-13).
INSERT INTO session (activity_id, space_id, session_date, start_time, end_time)
VALUES (14, 10, '2026-06-01', '09:00', '10:00');

-- Falha: 50 vagas em uma sala com capacidade 35.
-- ERRO ESPERADO: Vagas da sessão (50) excedem a capacidade do espaço (35).
INSERT INTO session (activity_id, space_id, session_date, start_time, end_time, requires_registration, max_vacancies)
VALUES (15, 11, '2026-05-12', '09:00', '12:00', true, 50);
