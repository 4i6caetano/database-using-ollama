CREATE TABLE event
(
	event_id bigint GENERATED ALWAYS AS IDENTITY,
	start_date timestamp NOT NULL,
	end_date timestamp NOT NULL,
	event_name varchar(200) NOT NULL,
	category text NOT NULL,
	capacity integer NOT NULL

	CONSTRAINT pk_event_id PRIMARY KEY(event_id),
	CONSTRAINT uq_event_name_start_date UNIQUE(event_name, start_date)
);

CREATE TABLE activity
(
	activity_id bigint GENERATED ALWAYS AS IDENTITY,
	activity_title varchar(200) NOT NULL,
	description text,
	activity_category text

	CONSTRAINT pk_activity_id PRIMARY KEY(activity_id),
);

CREATE TABLE space
(
	space_id bigint GENERATED ALWAYS AS IDENTITY,
	space_name varchar(200) NOT NULL,
	space_capacity integer NOT NULL,
	space_category varchar(200) NOT NULL

	CONSTRAINT pk_space_id PRIMARY KEY(space_id),
	CONSTRAINT uq_space_name UNIQUE(space_name)
);

CREATE TABLE resource
(
	resource_id bigint GENERATED ALWAYS AS IDENTITY,
	resource_name text NOT NULL,
	unit_cost NUMERIC(10,2) NOT NULL

	CONSTRAINT pk_resource_id PRIMARY KEY(resource_id),
	CONSTRAINT uq_resource_name UNIQUE(resource_name)
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
	complement text

	CONSTRAINT pk_adress_id PRIMARY KEY(adress_id),
);

CREATE TABLE person
(
	person_id bigint GENERATED ALWAYS AS IDENTITY,
	cpf varchar(11) NOT NULL,
	birth_date date NOT NULL,
	person_name text NOT NULL,
	gender varchar(20) NOT NULL,
	email text NOT NULL,
	occupation text

	CONSTRAINT pk_person_id PRIMARY KEY(person_id),
	CONSTRAINT uq_cpf UNIQUE(cpf)
);

Create TABLE legal_entity
(
	entity_id bigint GENERATED ALWAYS AS IDENTITY,
	cnpj varchar(14) NOT NULL,
	entity_name text NOT NULL,
	contact_email text NOT NULL

	CONSTRAINT pk_entity_id PRIMARY KEY(entity_id),
	CONSTRAINT uq_cnpj UNIQUE(cnpj)
);