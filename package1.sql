CREATE OR REPLACE PACKAGE traveler_assistance_package AS
    TYPE country_demographic IS RECORD (
        country_name       countries.country_name%TYPE,
        country_location   countries.location%TYPE,
        population         countries.population%TYPE,
        airports           countries.airports%TYPE,
        climate            countries.climate%TYPE
    );
    TYPE country_type IS RECORD (
        country_name   countries.country_name%TYPE,
        region         regions.region_name%TYPE,
        currency       currencies.currency_name%TYPE
    );
    TYPE countries_type IS TABLE OF country_type INDEX BY PLS_INTEGER;
    TYPE country_language_type IS RECORD (
        country_name        countries.country_name%TYPE,
        language_name       languages.language_name%TYPE,
        official_language   spoken_languages.official%TYPE
    );
    TYPE country_languages_type IS
        TABLE OF country_language_type INDEX BY PLS_INTEGER;
    PROCEDURE country_demographics (
        v_country_name   IN    VARCHAR2,
        country          OUT   country_demographic
    );

    PROCEDURE find_region_and_currency (
        v_country_name   IN    VARCHAR2,
        country          OUT   country_type
    );

    PROCEDURE countries_in_same_region (
        v_region_name   IN    VARCHAR2,
        countries       OUT   countries_type
    );

    PROCEDURE print_region_array (
        countries countries_type
    );

    PROCEDURE country_languages (
        v_country_name   IN    VARCHAR2,
        country_lang     OUT   country_languages_type
    );

    PROCEDURE print_language_array (
        country_langs country_languages_type
    );

END;

CREATE OR REPLACE PACKAGE BODY traveler_assistance_package AS

    PROCEDURE country_demographics (
        v_country_name   IN    VARCHAR2,
        country          OUT   country_demographic
    ) IS
    BEGIN
        SELECT
            c.country_name,
            c.location,
            c.population,
            c.airports,
            c.climate
        INTO country
        FROM
            countries c
        WHERE
            lower(country_name) = lower(v_country_name);

    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'No data found for country ' || v_country_name);
    END;

    PROCEDURE find_region_and_currency (
        v_country_name   IN    VARCHAR2,
        country          OUT   country_type
    ) IS
    BEGIN
        SELECT
            c.country_name,
            r.region_name,
            cu.currency_name
        INTO country
        FROM
            countries    c
            JOIN regions      r ON c.region_id = r.region_id
            JOIN currencies   cu ON c.currency_code = cu.currency_code
        WHERE
            lower(c.country_name) = lower(v_country_name);

    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'No data found for country ' || v_country_name);
    END;

    PROCEDURE countries_in_same_region (
        v_region_name   IN    VARCHAR2,
        countries       OUT   countries_type
    ) IS

        CURSOR countries_region IS
        SELECT
            c.country_name,
            r.region_name,
            cu.currency_name
        FROM
            countries    c,
            regions      r,
            currencies   cu
        WHERE
            c.region_id = r.region_id
            AND c.currency_code = cu.currency_code
            AND lower(r.region_name) = lower(v_region_name);

        i PLS_INTEGER := 1;
    BEGIN
        FOR country IN countries_region LOOP
            countries(i) := country;
            i := i + 1;
        END LOOP;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'No data found for country ' || v_region_name);
    END;

    PROCEDURE print_region_array (
        countries countries_type
    ) IS
    BEGIN
        FOR i IN countries.first..countries.last LOOP
            dbms_output.put_line(countries(i).country_name
                                 || ', '
                                 || countries(i).region
                                 || ', '
                                 || countries(i).currency);
        END LOOP;
    END;

    PROCEDURE country_languages (
        v_country_name   IN    VARCHAR2,
        country_lang     OUT   country_languages_type
    ) IS

        CURSOR country_languages_cursor IS
        SELECT
            c.country_name,
            l.language_name,
            sl.official
        FROM
            countries          c,
            languages          l,
            spoken_languages   sl
        WHERE
            lower(c.country_name) = lower(v_country_name)
            AND c.country_id = sl.country_id
            AND sl.language_id = l.language_id;

        i PLS_INTEGER := 1;
    BEGIN
        FOR country_language IN country_languages_cursor LOOP
            country_lang(i) := country_language;
            i := i + 1;
        END LOOP;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'No data found for country ' || v_country_name);
    END;
    --P6

    PROCEDURE print_language_array (
        country_langs country_languages_type
    ) IS
    BEGIN
        FOR i IN country_langs.first..country_langs.last LOOP
            dbms_output.put_line(country_langs(i).country_name
                                 || ', '
                                 || country_langs(i).language_name
                                 || ', '
                                 || country_langs(i).official_language);
        END LOOP;
    END;

END;
-- Tests

SET SERVEROUTPUT ON

DECLARE
    country_name   VARCHAR2(50) := 'Canada';
    country        traveler_assistance_package.country_demographic;
BEGIN
    traveler_assistance_package.country_demographics(country_name, country);
    dbms_output.put_line(country.country_name
                         || ',  '
                         || country.country_location
                         || ', '
                         || country.population
                         || ', '
                         || country.airports
                         || ', '
                         || country.climate);

END;

SET SERVEROUTPUT ON

DECLARE
    country_name   VARCHAR2(50) := 'Canada';
    country        traveler_assistance_package.country_type;
BEGIN
    traveler_assistance_package.find_region_and_currency(country_name, country);
    dbms_output.put_line(country.country_name
                         || ', '
                         || country.region
                         || ', '
                         || country.currency);

END;
--Tests 3,4
SET SERVEROUTPUT ON
DECLARE
    region_name VARCHAR2(50) := 'Eastern Europe';
    countries TRAVELER_ASSISTANCE_PACKAGE.countries_type;
BEGIN
    TRAVELER_ASSISTANCE_PACKAGE.COUNTRIES_IN_SAME_REGION(region_name, countries);
    DBMS_OUTPUT.PUT_LINE('Countries in the same region are: ');
    TRAVELER_ASSISTANCE_PACKAGE.PRINT_REGION_ARRAY(countries);
END;

--Test 5,6 

SET SERVEROUTPUT ON

DECLARE
    country_name    VARCHAR2(50) := 'Belize';
    country_langs   traveler_assistance_package.country_languages_type;
BEGIN
    traveler_assistance_package.country_languages(country_name, country_langs);
    dbms_output.put_line('Languages spoken in '
                         || country_name
                         || ' are: ');
    traveler_assistance_package.print_language_array(country_langs);
END;