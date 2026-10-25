CREATE OR REPLACE FUNCTION fn_event_total_capacity_constraint()
RETURNS trigger AS $$
DECLARE
	v_event_capacity integer;
	v_current_attendees integer;
BEGIN

	SELECT event_capacity INTO v_event_capacity
	FROM event
	WHERE event_id = NEW.event_id;

	SELECT count(*) INTO v_current_attendees
	FROM event_attendee
	WHERE event_id = NEW.event_id;

	IF (v_current_attendees >= v_event_capacity) THEN
		RAISE EXCEPTION 'Event total capacity reached';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_event_total_capacity_constraint
BEFORE INSERT OR UPDATE ON event_attendee
FOR EACH ROW
EXECUTE FUNCTION fn_event_total_capacity_constraint();




CREATE OR REPLACE FUNCTION fn_same_instant_sessions_constraint()
RETURNS trigger AS $$
BEGIN

	PERFORM 1
	FROM session
	WHERE space_id = NEW.space_id
		AND session_date = NEW.session_date
	  	AND (NEW.start_time, NEW.end_time) OVERLAPS (start_time, end_time)
	  	AND session_id != COALESCE(NEW.session_id, -1);

	IF FOUND THEN
		RAISE EXCEPTION 'There is already a session booked in this space and time';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tg_same_instant_sessions_constraint
BEFORE INSERT OR UPDATE ON session
FOR EACH ROW
EXECUTE FUNCTION fn_same_instant_sessions_constraint();