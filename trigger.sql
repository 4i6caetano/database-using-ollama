CREATE OR REPLACE FUNCTION fn_event_total_capacity_constraint()
RETURNS trigger AS $$
DECLARE
	v_event_capacity integer;
	v_current_attendees text;
BEGIN

	SELECT event_capacity INTO v_event_capacity
	FROM event
	WHERE event_id = NEW.event_id;

	SELECT count(*) INTO v_current_attendees
	FROM event_attendee
	WHERE event_id = NEW.event_id;

	IF (v_current_attendees >= v_event_capacity) THEN
		RAISE EXCEPTION 'Event total capacity reached'
	END IF
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_event_total_capacity_constraint
BEFORE INSERT OR UPDATE ON event_attendee
FOR EACH ROW
EXECUTE FUNCTION fn_event_total_capacity_constraint();




CREATE OR REPLACE FUNCTION fn_name()
RETURNS trigger AS $$
DECLARE

BEGIN

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_trigger_name
BEFORE INSERT OR UPDATE ON tabela
FOR EACH ROW
EXECUTE FUNCTION fn_name()