"""

Summit Public Schools

• This python script connects to Illuminate CA + Illuminate WA databases
• Queries student demographics information from both databases based on this query:
https://github.com/SummitPublicSchools/Illuminate-Education/blob/master/Student_Demographics.sql
• Finally, the script combines the CA + WA datasets into one dataset

"""

import psycopg2 as pg
import pandas as pd
import ConfigParser as cp
import time


def main():

    query = """
        SELECT DISTINCT
            'Summit Public Schools' AS "SPS"  -- for Tableau purposes
          , TRIM(sites.site_name) AS "Site"
          , grade_levels.short_name::INTEGER AS "Grade Level"
          , students.local_student_id AS "Student ID"
          , students.student_id AS "Illuminate Student ID"
          , students.state_student_id AS "State Student ID"
          , TRIM(students.last_name) AS "Student Last Name"
          , TRIM(students.first_name) AS "Student First Name"
          , TRIM(students.middle_name) AS "Student Middle Name"
          , LOWER(students.email) AS "Student Email"
          , users.last_name AS "Mentor Last Name"
          , users.first_name AS "Mentor First Name"
          , LOWER(users.email1) AS "Mentor Email"
          , students.school_enter_date AS "School Enter Date"
          , students.birth_date AS "Birth Date"
          , students.gender AS "Gender"
          , race_ethnicity.combined_race_ethnicity AS "Federal Reported Race"
          , students.is_hispanic AS "Hispanic / Latino Status"
          , el.code_translation AS "English Proficiency"
          , demographics.sed AS "SED Status"
          , demographics.is_specialed AS "SPED Status"


        FROM
          -- Start with ss_current to pull only currently enrolled students
          matviews.ss_current AS ss

          -- Join current students to students, grade levels, and sites
          INNER JOIN students
            USING (student_id)
          INNER JOIN grade_levels
            USING (grade_level_id)
          INNER JOIN sites
            ON sites.site_id = ss.site_id
            AND sites.exclude_from_current_sites IS FALSE   -- excludes SPS as a district

          -- Join current students to counselors (mentors)
          LEFT OUTER JOIN student_counselor_aff AS counselors
            ON counselors.student_id = ss.student_id
            AND counselors.start_date <= CURRENT_DATE
            AND (counselors.end_date IS NULL OR counselors.end_date > CURRENT_DATE)
          LEFT OUTER JOIN users
            ON counselors.user_id = users.user_id

          -- Join current students to demographics
          LEFT OUTER JOIN codes.english_proficiency AS el
            ON el.code_id = students.english_proficiency
          LEFT OUTER JOIN race_ethnicity_combined AS race_ethnicity
            ON race_ethnicity.student_id = ss.student_id
          LEFT OUTER JOIN student_common_demographics AS demographics
            ON demographics.student_id = ss.student_id


        WHERE
              sites.site_name <> 'SPS Tour'
          -- AND ss.leave_date > CURRENT_DATE


        ORDER BY
            "Site"
          , "Grade Level"
          , "Student Last Name"
          , "Student First Name"
    ;"""


    ## load Illuminate configuration file
    config = cp.ConfigParser()
    config.read('illuminate.config')    # use the illuminate.configTEMPLATE


    ## Illuminate CA
    # connect to Illuminate CA

    host_ca = config.get('Illuminate CA', 'host')
    port_ca = config.get('Illuminate CA', 'port')
    dbname_ca = config.get('Illuminate CA', 'dbname')
    user_ca = config.get('Illuminate CA', 'user')
    password_ca = config.get('Illuminate CA', 'password')

    print "\nIlluminate CA: Connecting to database..."
    connection_illuminate_ca = pg.connect(host = host_ca, port = port_ca, dbname = dbname_ca, user = user_ca, password = password_ca)
    print "Illuminate CA: Connected!"

    # execute query
    print "Illuminate CA: Executing query..."
    df_ca = pd.read_sql(query, connection_illuminate_ca)

    # return the number of records that resulted from the query
    records_ca = len(df_ca.index)
    print "Illuminate CA: %d records returned" % records_ca


    ## Illuminate WA
    # connect to Illuminate WA
    host_wa = config.get('Illuminate WA', 'host')
    port_wa = config.get('Illuminate WA', 'port')
    dbname_wa = config.get('Illuminate WA', 'dbname')
    user_wa = config.get('Illuminate WA', 'user')
    password_wa = config.get('Illuminate WA', 'password')

    print "\nIlluminate WA: Connecting to database..."
    connection_illuminate_wa = pg.connect(host = host_wa, port = port_wa, dbname = dbname_wa, user = user_wa, password = password_wa)
    print "Illuminate WA: Connected!"

    # execute query
    print "Illuminate WA: Executing query..."
    df_wa = pd.read_sql(query, connection_illuminate_wa)

    # return the number of records that resulted from the query
    records_wa = len(df_wa.index)
    print "Illuminate WA: %d records returned" % records_wa

    ## CA + WA
    records = records_ca + records_wa
    print "\nIlluminate CA + WA: %d records returned" % records

    ## write to csv
    current_date = time.strftime("%Y%m%d")
    filename = current_date + ' Illuminate Current Student Demographics.csv'
    # df = pd.DataFrame(records)

    df = pd.concat([df_ca, df_wa], axis = 0)

    df.to_csv(filename, header = True, index = False)

    print "\nExported to \"%s Illuminate Current Student Demographics.csv\"\n" % current_date


if __name__ == "__main__":
    main()
