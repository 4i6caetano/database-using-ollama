--Entities

CREATE TABLE event
(
	event_id bigint GENERATED ALWAYS AS IDENTITY,
	start_date timestamp NOT NULL,
	end_date timestamp NOT NULL,
	event_name varchar(200) NOT NULL,
	event_category text NOT NULL,
	event_capacity integer NOT NULL,

	adress_id bigint NOT NULL,

	CONSTRAINT pk_event_id PRIMARY KEY(event_id),
	
	CONSTRAINT uq_event_name_start_date UNIQUE(event_name, start_date),

	CONSTRAINT fk_event_adress_id FOREIGN KEY(adress_id) 
		REFERENCES adress(adress_id) ON UPDATE CASCADE ON DELETE RESTRICT

	CONSTRAINT ck_event_category CHECK(event_category IN
	('technology' OR 'art & culture' OR 'science' OR 'business' OR 'entertainment' OR 'music')),

	CONSTRAINT ck_event_capacity CHECK(event_capacity > 0)
);

CREATE TABLE activity
(
	activity_id bigint GENERATED ALWAYS AS IDENTITY,
	activity_title varchar(200) NOT NULL,
	description text,
	activity_category text,

	event_id bigint NOT NULL,

	CONSTRAINT pk_activity_id PRIMARY KEY(activity_id),
	
	CONSTRAINT fk_event_id FOREIGN KEY(event_id) 
		REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE RESTRICT

	CONSTRAINT ck_activity_category CHECK(activity_category IN
	('technology' OR 'art & culture' OR 'science' OR 'business' OR 'entertainment' OR 'music')),
);

CREATE TABLE space
(
	space_id bigint GENERATED ALWAYS AS IDENTITY,
	space_name varchar(200) NOT NULL,
	space_capacity integer NOT NULL,
	space_category varchar(200) NOT NULL,

	CONSTRAINT pk_space_id PRIMARY KEY(space_id),
	
	CONSTRAINT uq_space_name UNIQUE(space_name),

	CONSTRAINT ck_space_capacity CHECK(space_capacity > 0),

	CONSTRAINT ck_space_category CHECK(space_category IN
	('lecture' OR 'clasroom' OR 'auditorium' OR 'exhibition_hall' OR 'meeting_room' OR 'outdoor area' OR 'virtual_room')),
);

CREATE TABLE resource
(
	resource_id bigint GENERATED ALWAYS AS IDENTITY,
	resource_name text NOT NULL,
	unit_cost NUMERIC(10,2) NOT NULL DEFAULT 0.00,

	CONSTRAINT pk_resource_id PRIMARY KEY(resource_id),
	CONSTRAINT uq_resource_name UNIQUE(resource_name),

	CONSTRAINT ck_unit_cost CHECK(unit_cost > 0)
);

CREATE TABLE address
(
	adress_id bigint GENERATED ALWAYS AS IDENTITY,
	cep varchar(8) NOT NULL,
	street text NOT NULL,
	adress_number text NOT NULL,
	neighborhood text NOT NULL,
	city text NOT NULL,
	adress_state varchar(2) NOT NULL,
	complement text,
	adress_type text NOT NULL,
	adress_capacity integer

	CONSTRAINT pk_adress_id PRIMARY KEY(adress_id),

	CONSTRAINT uq_cep UNIQUE(cep),

	CONSTRAINT ck_adress_type CHECK(adress_type IN ('residential' OR 'event')),

	CONSTRAINT ck_adress_capacity CHECK(adress_type IS 'residential' OR adress_capacity IS NOT NULL)
);

CREATE TABLE person
(
	person_id bigint GENERATED ALWAYS AS IDENTITY,
	cpf varchar(11) NOT NULL,
	birth_date date NOT NULL,
	person_name text NOT NULL,
	gender varchar(20) NOT NULL,
	email text NOT NULL,
	occupation text,

	adress_id bigint NOT NULL,

	CONSTRAINT pk_person_id PRIMARY KEY(person_id),
	
	CONSTRAINT uq_cpf UNIQUE(cpf), 

	CONSTRAINT fk_person_adress_id FOREIGN KEY(adress_id) REFERENCES adress(adress_id)
		ON UPDATE CASCADE ON DELETE RESTRICT,

	CONSTRAINT ck_gender CHECK(gender IN
		('Male' OR 'FEMALE' OR "Non binary" OR "Prefer not to disclose"))
);

Create TABLE legal_entity
(
	entity_id bigint GENERATED ALWAYS AS IDENTITY,
	cnpj varchar(14) NOT NULL,
	entity_name text NOT NULL,
	contact_email text NOT NULL,

	CONSTRAINT pk_entity_id PRIMARY KEY(entity_id),
	CONSTRAINT uq_cnpj UNIQUE(cnpj)
);

-- Associative Entity

CREATE TABLE session
(
	session_id bigint GENERATED ALWAYS AS IDENTITY,
	activity_id bigint NOT NULL,
	space_id bigint NOT NULL,
	session_date bigint NOT NULL,
	start_time date NOT NULL,
	end_time time NOT NULL,
	requires_registration boolean NOT NULL DEFAULT false,
	max_vacancies integer,

	CONSTRAINT pk_session_id PRIMARY KEY (session_id),
	
    CONSTRAINT ck_session_time CHECK (end_time > start_time),
    CONSTRAINT ck_session_vacancies CHECK (max_vacancies IS NULL OR max_vacancies > 0),
	
    CONSTRAINT fk_session_activity FOREIGN KEY (activity_id)
        REFERENCES activity(activity_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_session_space FOREIGN KEY (space_id)
        REFERENCES space(space_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Heritage

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


-- Associative tables

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

CREATE TABLE space_resource
(
    space_id bigint NOT NULL,
    resource_id bigint NOT NULL,
    quantity integer NOT NULL DEFAULT 1,
	
    CONSTRAINT pk_space_resource PRIMARY KEY (space_id, resource_id),
	
    CONSTRAINT ck_space_resource_quantity CHECK (quantity > 0),
	
    CONSTRAINT fk_space_resource_space FOREIGN KEY (space_id)
        REFERENCES space(space_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_space_resource_resource FOREIGN KEY (resource_id)
        REFERENCES resource(resource_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE event_sponsor
(
    event_id bigint NOT NULL,
    legal_entity_id bigint NOT NULL,
    sponsorship_value numeric(12, 2),
	
    CONSTRAINT pk_event_sponsor PRIMARY KEY (event_id, legal_entity_id),
	
    CONSTRAINT ck_event_sponsor_value CHECK (sponsorship_value >= 0),
	
    CONSTRAINT fk_event_sponsor_event FOREIGN KEY (event_id)
        REFERENCES event(event_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_event_sponsor_company FOREIGN KEY (legal_entity_id)
        REFERENCES legal_entity(entity_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

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

CREATE TABLE person_address
(
    person_id bigint NOT NULL,
    address_id bigint NOT NULL,
	
    CONSTRAINT pk_person_address PRIMARY KEY (person_id, address_id),
	
    CONSTRAINT fk_person_address_person FOREIGN KEY (person_id)
        REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_person_address_address FOREIGN KEY (address_id)
        REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE session_attendee
(
    session_id bigint NOT NULL,
    person_id bigint NOT NULL,
    registration_date timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
	
    CONSTRAINT pk_session_attendee PRIMARY KEY (session_id, person_id),
	
    CONSTRAINT fk_session_attendee_session FOREIGN KEY (session_id)
        REFERENCES session(session_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_session_attendee_person FOREIGN KEY (person_id)
        REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE RESTRICT
);
