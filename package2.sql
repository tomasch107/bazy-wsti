CREATE OR REPLACE PACKAGE traveler_admin_package AS
    TYPE object_rec IS RECORD (
        name              user_dependencies.name%TYPE,
        type              user_dependencies.type%TYPE,
        referenced_name   user_dependencies.referenced_name%TYPE,
        referenced_type   user_dependencies.referenced_type%TYPE
    );
    TYPE object_array IS
        TABLE OF object_rec INDEX BY PLS_INTEGER;
    PROCEDURE display_disabled_triggers;

    FUNCTION all_dependent_objects (
        object_name VARCHAR2
    ) RETURN object_array;

    PROCEDURE print_dependent_objects (
        objects IN object_array
    );

END;

CREATE OR REPLACE PACKAGE BODY traveler_admin_package AS

    PROCEDURE display_disabled_triggers IS
        CURSOR triggers IS
        SELECT
            trigger_name
        FROM
            user_triggers
        WHERE
            status = 'DISABLED';

    BEGIN
        FOR trigger IN triggers LOOP
            dbms_output.put_line('Trigger '
                                 || trigger.trigger_name
                                 || ' is disabled');
        END LOOP;
    END;

    FUNCTION all_dependent_objects (
        object_name VARCHAR2
    ) RETURN object_array IS

        CURSOR object_cur IS
        SELECT
            name,
            type,
            referenced_name,
            referenced_type
        FROM
            user_dependencies
        WHERE
            referenced_name = upper(object_name);

        v_objects   object_array;
        i           PLS_INTEGER := 1;
    BEGIN
        FOR v_object IN object_cur LOOP
            v_objects(i) := v_object;
            i := i + 1;
        END LOOP;

        IF ( v_objects.count < 1 ) THEN
            RAISE no_data_found;
        END IF;
        RETURN v_objects;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'No data found');
    END;

    PROCEDURE print_dependent_objects (
        objects IN object_array
    ) IS
    BEGIN
        dbms_output.put_line('NAME          TYPE        REFERENCED_NAME         REFERENCED_TYPE');
        FOR i IN objects.first..objects.last LOOP dbms_output.put_line(rpad(objects(i).name, 31)
                                                                       || rpad(objects(i).type, 31)
                                                                       || rpad(objects(i).referenced_name, 31)
                                                                       || rpad(objects(i).referenced_type, 31));
        END LOOP;

    END;

END;

--Test 1

SELECT
    trigger_name
FROM
    user_triggers;
-- DISABLE trigger

ALTER TRIGGER display_salary_changes DISABLE;
--execute

SET SERVEROUTPUT ON

BEGIN
    traveler_admin_package.display_disabled_triggers();
END;
-- ENABLE trigger

ALTER TRIGGER display_salary_changes ENABLE;


-- Tests 2,3
-- control select

SELECT
    *
FROM
    user_dependencies
WHERE
    referenced_name = 'DEPARTMENTS';


--actual test
SET SERVEROUTPUT ON
DECLARE
    v_objects traveler_admin_package.object_array;
BEGIN
    v_objects := traveler_admin_package.all_dependent_objects('DEPARTMENTS');
    traveler_admin_package.print_dependent_objects(v_objects);
END;