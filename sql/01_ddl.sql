-- ------------------------------------------------------------
-- DDL - Sistema de Gestão de Eventos e Espaços (PostgreSQL)
-- ------------------------------------------------------------
-- Critério adotado para as ações referenciais:
--   * ON UPDATE CASCADE em todas as FKs: se uma chave mudar, as
--     referências acompanham (na prática as chaves são IDENTITY).
--   * ON DELETE CASCADE para dependentes fracos: especializações de
--     pessoa, atividades e sessões de um evento, histórico de sessão,
--     inscrições e tabelas associativas (sem o "dono" elas não fazem
--     sentido).
--   * ON DELETE RESTRICT para referências a cadastros: pessoa e seus
--     papéis, endereço, espaço, recurso, série, entidade jurídica. Um
--     cadastro em uso não pode ser apagado.
-- ------------------------------------------------------------


-- ENTIDADES PRINCIPAIS

-- Endereço de pessoas (residential) e de locais de evento (event).
CREATE TABLE address
(
	address_id bigint GENERATED ALWAYS AS IDENTITY,
	cep varchar(8) NOT NULL,
	street text NOT NULL,
	address_number text NOT NULL,
	neighborhood text NOT NULL,
	city text NOT NULL,
	address_state varchar(2) NOT NULL,
	complement text,
	address_type text NOT NULL,
	address_capacity integer,

	CONSTRAINT pk_address_id PRIMARY KEY(address_id),

	CONSTRAINT ck_cep CHECK(cep ~ '^[0-9]{8}$'),
	CONSTRAINT ck_address_type CHECK(address_type IN ('residential', 'event')),
	-- Endereço de evento precisa informar a capacidade do local.
	CONSTRAINT ck_address_capacity CHECK(address_type = 'residential' OR address_capacity IS NOT NULL)
);

-- Pessoa jurídica: empresa, universidade, associação etc.
CREATE TABLE legal_entity
(
	entity_id bigint GENERATED ALWAYS AS IDENTITY,
	cnpj varchar(14) NOT NULL,
	entity_name text NOT NULL,
	contact_email text NOT NULL,

	CONSTRAINT pk_entity_id PRIMARY KEY(entity_id),

	CONSTRAINT uq_cnpj UNIQUE(cnpj),

	CONSTRAINT ck_cnpj CHECK(cnpj ~ '^[0-9]{14}$'),
	CONSTRAINT ck_entity_email CHECK(contact_email LIKE '%@%')
);

-- Pessoa física: entidade base das especializações (papéis).
CREATE TABLE person
(
	person_id bigint GENERATED ALWAYS AS IDENTITY,
	cpf varchar(11) NOT NULL,
	birth_date date NOT NULL,
	person_name text NOT NULL,
	gender varchar(30) NOT NULL,
	email text NOT NULL,
	occupation text,

	address_id bigint NOT NULL,

	CONSTRAINT pk_person_id PRIMARY KEY(person_id),

	CONSTRAINT uq_cpf UNIQUE(cpf),

	CONSTRAINT fk_person_address_id FOREIGN KEY(address_id)
		REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_cpf CHECK(cpf ~ '^[0-9]{11}$'),
	CONSTRAINT ck_person_email CHECK(email LIKE '%@%'),
	CONSTRAINT ck_gender CHECK(gender IN
		('Male', 'Female', 'Non-binary', 'Prefer not to disclose'))
);


-- ESPECIALIZAÇÕES DE PERSON (sobrepostas: uma pessoa pode ter vários papéis)
-- A PK é a própria FK para person. Apagar a pessoa apaga seus papéis
-- (CASCADE), mas as participações em eventos/atividades usam RESTRICT,
-- então uma pessoa com histórico de participação não pode ser apagada.

CREATE TABLE organizer
(
	person_id bigint NOT NULL,

	CONSTRAINT pk_organizer PRIMARY KEY (person_id),

	CONSTRAINT fk_organizer_person FOREIGN KEY (person_id)
		REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE speaker
(
	person_id bigint NOT NULL,
	mini_bio text,

	CONSTRAINT pk_speaker PRIMARY KEY (person_id),

	CONSTRAINT fk_speaker_person FOREIGN KEY (person_id)
		REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE staff
(
	person_id bigint NOT NULL,
	role_description text,

	CONSTRAINT pk_staff PRIMARY KEY (person_id),

	CONSTRAINT fk_staff_person FOREIGN KEY (person_id)
		REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE attendee
(
	person_id bigint NOT NULL,
	institution text,

	CONSTRAINT pk_attendee PRIMARY KEY (person_id),

	CONSTRAINT fk_attendee_person FOREIGN KEY (person_id)
		REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- EVENTOS E PROGRAMAÇÃO

-- Série: o que é comum a todas as edições de um evento recorrente.
CREATE TABLE event_series
(
	series_id bigint GENERATED ALWAYS AS IDENTITY,
	series_name varchar(200) NOT NULL,
	description text,

	CONSTRAINT pk_series_id PRIMARY KEY(series_id),

	CONSTRAINT uq_series_name UNIQUE(series_name)
);

-- Evento: uma edição concreta de uma série.
CREATE TABLE event
(
	event_id bigint GENERATED ALWAYS AS IDENTITY,
	series_id bigint NOT NULL,
	edition_number integer NOT NULL,
	start_date date NOT NULL,
	end_date date NOT NULL,
	event_name varchar(200) NOT NULL,
	event_category text NOT NULL,
	event_capacity integer NOT NULL,

	address_id bigint NOT NULL,
	hosting_entity_id bigint,
	primary_organizer_id bigint,

	CONSTRAINT pk_event_id PRIMARY KEY(event_id),

	CONSTRAINT uq_series_edition UNIQUE(series_id, edition_number),
	CONSTRAINT uq_event_name_start_date UNIQUE(event_name, start_date),

	CONSTRAINT fk_event_series_id FOREIGN KEY(series_id)
		REFERENCES event_series(series_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_event_hosting_entity_id FOREIGN KEY(hosting_entity_id)
		REFERENCES legal_entity(entity_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_primary_organizer_id FOREIGN KEY (primary_organizer_id)
		REFERENCES organizer(person_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_event_address_id FOREIGN KEY(address_id)
		REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_edition_number CHECK(edition_number > 0),
	CONSTRAINT ck_event_dates CHECK(end_date >= start_date),
	CONSTRAINT ck_event_category CHECK(event_category IN
		('technology', 'art & culture', 'science', 'business', 'entertainment', 'music')),
	CONSTRAINT ck_event_capacity CHECK(event_capacity > 0),
	-- Todo evento precisa de ao menos um promotor (pessoa e/ou organização).
	CONSTRAINT ck_event_promoter CHECK
		(hosting_entity_id IS NOT NULL OR primary_organizer_id IS NOT NULL)
);

-- Atividade: o que é oferecido no programa (título, descrição, tipo).
CREATE TABLE activity
(
	activity_id bigint GENERATED ALWAYS AS IDENTITY,
	activity_title varchar(200) NOT NULL,
	description text,
	activity_category text NOT NULL,

	event_id bigint NOT NULL,

	CONSTRAINT pk_activity_id PRIMARY KEY(activity_id),

	CONSTRAINT fk_activity_event_id FOREIGN KEY(event_id)
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT ck_activity_category CHECK(activity_category IN
		('lecture', 'workshop', 'short_course', 'panel', 'round_table', 'presentation'))
);

-- Espaço físico ou virtual onde as sessões acontecem.
CREATE TABLE space
(
	space_id bigint GENERATED ALWAYS AS IDENTITY,
	space_name varchar(200) NOT NULL,
	space_capacity integer NOT NULL,
	space_category varchar(30) NOT NULL,

	CONSTRAINT pk_space_id PRIMARY KEY(space_id),

	CONSTRAINT uq_space_name UNIQUE(space_name),

	CONSTRAINT ck_space_capacity CHECK(space_capacity > 0),
	CONSTRAINT ck_space_category CHECK(space_category IN
		('classroom', 'auditorium', 'laboratory', 'exhibition_hall', 'meeting_room', 'outdoor_area', 'virtual_room'))
);

-- Recurso que um espaço pode possuir (projetor, computador...).
CREATE TABLE resource
(
	resource_id bigint GENERATED ALWAYS AS IDENTITY,
	resource_name text NOT NULL,
	unit_cost numeric(10,2) NOT NULL DEFAULT 0.00,

	CONSTRAINT pk_resource_id PRIMARY KEY(resource_id),

	CONSTRAINT uq_resource_name UNIQUE(resource_name),

	CONSTRAINT ck_unit_cost CHECK(unit_cost >= 0)
);


-- ENTIDADE ASSOCIATIVA

-- Sessão: realização concreta de uma atividade em um espaço, data e horário.
-- Guarda apenas a programação ATUAL; alterações vão para session_history.
CREATE TABLE session
(
	session_id bigint GENERATED ALWAYS AS IDENTITY,
	activity_id bigint NOT NULL,
	space_id bigint NOT NULL,
	session_date date NOT NULL,
	start_time time NOT NULL,
	end_time time NOT NULL,
	-- Atributo gerado: calculado automaticamente a partir dos horários.
	duration interval GENERATED ALWAYS AS (end_time - start_time) STORED,
	requires_registration boolean NOT NULL DEFAULT false,
	-- Limite próprio da sessão; se NULL vale a capacidade do espaço.
	max_vacancies integer,

	CONSTRAINT pk_session_id PRIMARY KEY (session_id),

	CONSTRAINT fk_session_activity FOREIGN KEY (activity_id)
		REFERENCES activity(activity_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_session_space FOREIGN KEY (space_id)
		REFERENCES space(space_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_session_time CHECK (end_time > start_time),
	CONSTRAINT ck_session_vacancies CHECK (max_vacancies IS NULL OR max_vacancies > 0)
);

-- Histórico de alterações de sessão (preenchido por trigger).
-- old_space_id é uma cópia do valor antigo, não uma FK: o registro
-- histórico deve permanecer mesmo que o espaço deixe de existir.
CREATE TABLE session_history
(
	history_id bigint GENERATED ALWAYS AS IDENTITY,
	session_id bigint NOT NULL,
	old_space_id bigint NOT NULL,
	old_session_date date NOT NULL,
	old_start_time time NOT NULL,
	old_end_time time NOT NULL,
	changed_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

	CONSTRAINT pk_session_history PRIMARY KEY (history_id),

	CONSTRAINT fk_session_history_session FOREIGN KEY (session_id)
		REFERENCES session(session_id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- TABELAS ASSOCIATIVAS (relacionamentos N:M)

-- Espaços disponibilizados para um evento.
CREATE TABLE event_space
(
	event_id bigint NOT NULL,
	space_id bigint NOT NULL,

	CONSTRAINT pk_event_space PRIMARY KEY (event_id, space_id),

	CONSTRAINT fk_event_space_event FOREIGN KEY (event_id)
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_event_space_space FOREIGN KEY (space_id)
		REFERENCES space(space_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Recursos disponíveis em cada espaço e a quantidade.
CREATE TABLE space_resource
(
	space_id bigint NOT NULL,
	resource_id bigint NOT NULL,
	quantity integer NOT NULL DEFAULT 1,

	CONSTRAINT pk_space_resource PRIMARY KEY (space_id, resource_id),

	CONSTRAINT fk_space_resource_space FOREIGN KEY (space_id)
		REFERENCES space(space_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_space_resource_resource FOREIGN KEY (resource_id)
		REFERENCES resource(resource_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_space_resource_quantity CHECK (quantity > 0)
);

-- Organizações que apoiam/patrocinam um evento.
CREATE TABLE event_sponsor
(
	event_id bigint NOT NULL,
	legal_entity_id bigint NOT NULL,
	sponsorship_value numeric(12, 2),

	CONSTRAINT pk_event_sponsor PRIMARY KEY (event_id, legal_entity_id),

	CONSTRAINT fk_event_sponsor_event FOREIGN KEY (event_id)
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_event_sponsor_company FOREIGN KEY (legal_entity_id)
		REFERENCES legal_entity(entity_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_event_sponsor_value CHECK (sponsorship_value >= 0)
);

-- Demais pessoas que organizam o evento (além do organizador principal).
CREATE TABLE event_organizer
(
	event_id bigint NOT NULL,
	person_id bigint NOT NULL,

	CONSTRAINT pk_event_organizer PRIMARY KEY (event_id, person_id),

	CONSTRAINT fk_event_organizer_event FOREIGN KEY (event_id)
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_event_organizer_organizer FOREIGN KEY (person_id)
		REFERENCES organizer(person_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Equipe de apoio (staff) que trabalha em cada evento.
CREATE TABLE event_staff
(
	event_id bigint NOT NULL,
	person_id bigint NOT NULL,

	CONSTRAINT pk_event_staff PRIMARY KEY (event_id, person_id),

	CONSTRAINT fk_event_staff_event FOREIGN KEY (event_id)
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_event_staff_staff FOREIGN KEY (person_id)
		REFERENCES staff(person_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Palestrantes/instrutores de cada atividade.
CREATE TABLE activity_speaker
(
	activity_id bigint NOT NULL,
	person_id bigint NOT NULL,

	CONSTRAINT pk_activity_speaker PRIMARY KEY (activity_id, person_id),

	CONSTRAINT fk_activity_speaker_activity FOREIGN KEY (activity_id)
		REFERENCES activity(activity_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_activity_speaker_speaker FOREIGN KEY (person_id)
		REFERENCES speaker(person_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Inscrição de um participante em um evento (dá acesso à programação geral).
CREATE TABLE event_attendee
(
	event_id bigint NOT NULL,
	person_id bigint NOT NULL,
	registration_date timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
	registration_status varchar(10) NOT NULL DEFAULT 'confirmed',

	CONSTRAINT pk_event_attendee PRIMARY KEY (event_id, person_id),

	CONSTRAINT fk_event_attendee_event FOREIGN KEY (event_id)
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_event_attendee_attendee FOREIGN KEY (person_id)
		REFERENCES attendee(person_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_event_attendee_status CHECK (registration_status IN ('confirmed', 'cancelled'))
);

-- Inscrição adicional em uma sessão que exige inscrição (vagas limitadas).
CREATE TABLE session_attendee
(
	session_id bigint NOT NULL,
	person_id bigint NOT NULL,
	registration_date timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
	registration_status varchar(10) NOT NULL DEFAULT 'confirmed',

	CONSTRAINT pk_session_attendee PRIMARY KEY (session_id, person_id),

	CONSTRAINT fk_session_attendee_session FOREIGN KEY (session_id)
		REFERENCES session(session_id) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_session_attendee_attendee FOREIGN KEY (person_id)
		REFERENCES attendee(person_id) ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_session_attendee_status CHECK (registration_status IN ('confirmed', 'cancelled'))
);
