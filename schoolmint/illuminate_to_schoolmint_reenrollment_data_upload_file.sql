/******************************************************************************
* Author: Patrick Yoho
* Last modified on: May 15, 2018
* Last modified by: Mario Palmisano
*
* This query is used to pull data for returning students out of Illuminate
* for the purpose of uploading it to SchoolMint.  This allows us to populate
* returning students' data (especially contact data) into forms for verification
* on Summer Mailers. The end product should align with the SchoolMint upload
* template.
*
* This query makes use of the contact_info_starter-long_or_wide query which sets
* the business rules for Parent/Guardian 1, Parent/Guardian 2, Emergency Contact 1,
* and Emergency Contact 2.
*
******************************************************************************/

WITH
/*******************************
CONTACTS RANKED BY RELATIONSHIP
This helps choose the correct parent/guardian two.
It essentially takes the contacts.students_contact_info view and
adds a ranking, as well as the translation for the correspondance_language code.
*******************************/
  contacts_ranked AS (
    SELECT
    contact_types_ranked.*,
    CASE
      WHEN contact_types_ranked.contact_type = 'Mother' THEN 'MO'
      WHEN contact_types_ranked.contact_type = 'Father' THEN 'FA'
      WHEN contact_types_ranked.contact_type = 'Stepfather' THEN 'SFA'
      WHEN contact_types_ranked.contact_type = 'Stepmother' THEN 'SMO'
      WHEN contact_types_ranked.contact_type = 'Sibling' THEN 'SB'
      WHEN contact_types_ranked.contact_type = 'Aunt' THEN 'AU'
      WHEN contact_types_ranked.contact_type = 'Uncle' THEN 'UN'
      WHEN contact_types_ranked.contact_type = 'Brother' THEN 'BR'
      WHEN contact_types_ranked.contact_type = 'Sister' THEN 'SI'
      WHEN contact_types_ranked.contact_type = 'Cousin' THEN 'CO'
      WHEN (contact_types_ranked.contact_type = 'Grandparent' OR
            contact_types_ranked.contact_type = 'Grandfather' OR
            contact_types_ranked.contact_type = 'Grandmother') THEN 'GP'
      WHEN (contact_types_ranked.contact_type = 'Caretaker' OR 
            contact_types_ranked.contact_type = 'Court Guardian' OR
            contact_types_ranked.contact_type = 'Agency Representative' OR
            contact_types_ranked.contact_type = 'Agency Rep' OR
            contact_types_ranked.contact_type = 'Parent/Guardian') THEN 'CT'
      WHEN (contact_types_ranked.contact_type = 'Foster Parent' OR
            contact_types_ranked.contact_type = 'Foster Father' OR
            contact_types_ranked.contact_type = 'Foster Mother') THEN 'FP'
      ELSE 'OT'
      END AS "contact_type_sm", --SchoolMint contact type codes
    codes.language.code_translation AS correspondance_language_text,
    codes.parent_education.code_translation AS education_level_text,
    codes.marital_status.code_translation AS maritial_status_text,
    ROW_NUMBER() OVER (
      PARTITION BY student_id
      ORDER BY
        (CASE WHEN primary_household THEN 1 WHEN primary_household IS NULL THEN 2 ELSE 3 END),
        (CASE WHEN primary_contact THEN 1 WHEN primary_contact IS NULL THEN 2 ELSE 3 END),
        (CASE WHEN resides_with THEN 1 WHEN resides_with IS NULL THEN 2 ELSE 3 END),
        (CASE WHEN is_legal THEN 1 WHEN is_legal IS NULL THEN 2 ELSE 3 END),
        contact_types_ranked
    ) AS contact_rank
    FROM (
      SELECT *,
      CASE WHEN contact_type = 'Mother' OR contact_type = 'Father' THEN 1
           WHEN contact_type = 'Stepfather' OR contact_type = 'Stepmother' THEN 2
           WHEN contact_type = 'Aunt' OR contact_type = 'Uncle' THEN 3
           WHEN contact_type = 'Grandparent' OR contact_type = 'Grandmother' OR
             contact_type = 'Grandfather' THEN 4
           WHEN contact_type = 'Parent/Guardian' THEN 5
           WHEN contact_type = 'Other' THEN 6
           WHEN contact_type = 'Brother' OR contact_type = 'Sister' OR
             contact_type = 'Sibling' THEN 7
           WHEN contact_type = 'Court Guardian' OR contact_type = 'Caretaker' THEN 8
           WHEN contact_type = 'Foster Mother' OR contact_type = 'Foster Father' OR
             contact_type = 'Foster Parent' THEN 9
           WHEN contact_type = 'Agency Rep' THEN 10
           WHEN contact_type = 'Cousin' THEN 11
           ELSE 12
      END AS contact_type_rank
      FROM contacts.students_contact_info
    ) AS contact_types_ranked
    LEFT JOIN codes.language ON correspondance_language_id = codes.language.code_id
    LEFT JOIN codes.parent_education ON education_level_id = codes.parent_education.code_id
    LEFT JOIN codes.marital_status ON marital_status_id = codes.marital_status.code_id
  ),

/*********************************
ADDRESSES - PHYSICAL AND MAILING
There are 3 Common Table Expressions (CTEs) here.
1.) addresses_ranked
Grabs all of the addresses and enumerates them by contact in order of the movein_date.
2.) current_physical_addresses
This just renames columns to pull a physical address. It only grabs addresses
where moveout_date is null.
3.) mailing_addresses
This renames columns to pull a mailing address.
It also provides a row_number ranking by movein_date
in order for us to choose the most recent
mailing address. It only grabs addresses where moveout_date is null
*********************************/
  -- All Addresses with a ranking
  addresses_ranked AS (
    SELECT DISTINCT
      --student_id,
      contact_id,
      dwelling_id,
      address,
      address_2,
      city,
      codes.states.code_key AS state,
      zip,
      household_id,
      primary_household AS is_primary_household,
      hda.is_primary AS is_primary_dwelling,
      is_mailing AS is_mailing_dwelling,
      movein_date,
      moveout_date,
      ROW_NUMBER() OVER (
        PARTITION BY contact_id, household_id --, is_primary
        ORDER BY hda.is_primary DESC, hda.movein_date DESC
      ) AS dwelling_rank
    FROM contacts.students_contact_info
      LEFT JOIN contacts.household_dwelling_aff hda USING (household_id)
      LEFT JOIN contacts.dwellings USING (dwelling_id)
      LEFT JOIN codes.states ON contacts.dwellings.state = codes.states.code_id

    ORDER BY household_id, contact_id, dwelling_rank
  ),

  -- Only gives physical addresses where moveout_date is null
  current_physical_addresses AS (
    SELECT
      contact_id AS physical_addresses_contact_id,
      household_id AS physical_addresses_household_id,
      dwelling_id AS physical_addresses_dwelling_id,
      address AS physical_address_line_1,
      address_2 AS physical_address_line_2,
      city AS physical_address_city,
      state AS physical_address_state,
      zip AS physical_address_zip,
      movein_date AS physical_address_movein_date,
      moveout_date AS physical_address_moveout_date,
      dwelling_rank AS physical_address_dwelling_rank,
      -- DEBUG
      is_primary_dwelling,
      is_mailing_dwelling,
      -- /DEBUG
      ROW_NUMBER()
        OVER (
          PARTITION BY contact_id, household_id
          ORDER BY movein_date DESC
        ) AS physical_address_rank

    FROM addresses_ranked

    WHERE
      (is_primary_dwelling IS TRUE AND is_mailing_dwelling IS TRUE) OR
      is_mailing_dwelling IS FALSE AND
      moveout_date IS NULL
  ),

  -- Only gives mailing addresses where moveout_date is null
  current_mailing_addresses AS (
    SELECT
        contact_id AS mailing_addresses_contact_id,
        household_id AS mailing_addresses_household_id,
        dwelling_id AS mailing_addresses_dwelling_id,
        address AS mailing_address_line_1,
        address_2 AS mailing_address_line_2,
        city AS mailing_address_city,
        state AS mailing_address_state,
        zip AS mailing_address_zip,
        movein_date AS mailing_address_movein_date,
        moveout_date AS mailing_address_moveout_date,
        dwelling_rank AS mailing_address_dwelling_rank,
        ROW_NUMBER()
        OVER (
          PARTITION BY contact_id, household_id
          ORDER BY movein_date DESC
          ) AS mailing_address_rank
      FROM addresses_ranked
      WHERE is_mailing_dwelling IS TRUE
      AND moveout_date IS NULL
  ),

/*********************************
PHONE NUMBERS
*********************************/
  phones_ranked AS (
    SELECT DISTINCT
        contacts.contact_phones.contact_id AS contact_id,
        contacts.contact_phones.phone      AS phone_number,
        codes.phone_type.code_translation  AS phone_type,
        contacts.contact_phones.is_primary,
        rank()
        OVER (PARTITION BY contact_id, phone_type_id
          ORDER BY is_primary DESC, phone DESC)        AS phone_rank

      FROM contacts.contact_phones
        LEFT JOIN codes.phone_type
          ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

      -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown

      ORDER BY contact_id, phone_rank
  ),

  cell_phones_ranked AS (
    SELECT
      contact_id,
      phone_number AS cell_phone_number,
      phone_rank AS cell_phone_rank,
      is_primary AS cell_phone_is_primary
    FROM phones_ranked
    WHERE phone_type = 'Cellular'
  ),

  home_phones_ranked AS (
    SELECT
      contact_id,
      phone_number AS home_phone_number,
      phone_rank AS home_phone_rank,
      is_primary AS home_phone_is_primary
    FROM phones_ranked
    WHERE phone_type = 'Home'
  ),

  work_phones_ranked AS (
    SELECT
      contact_id,
      phone_number AS work_phone_number,
      phone_rank AS work_phone_rank,
      is_primary AS work_phone_is_primary
    FROM phones_ranked
    WHERE phone_type = 'Work'
  ),

/*********************************
FULL SET OF CONTACT INFO AND SEPARATION INTO LEGAL AND EMERGENCY
Only grab the most current physical and mail addresses and
the top-ranked phone numbers. At this point, this will
give us all of the contact info in LONG form
*********************************/
  contact_info_one_row_per_stu_contact_pair AS (
    SELECT DISTINCT*

    FROM
      contacts_ranked
      LEFT JOIN contacts.contacts USING(contact_id)
      LEFT JOIN current_physical_addresses
        ON contacts_ranked.contact_id = current_physical_addresses.physical_addresses_contact_id AND
           contacts_ranked.household_id = current_physical_addresses.physical_addresses_household_id
      LEFT JOIN current_mailing_addresses
        ON contacts_ranked.contact_id = current_mailing_addresses.mailing_addresses_contact_id AND
           contacts_ranked.household_id = current_mailing_addresses.mailing_addresses_household_id
      LEFT JOIN cell_phones_ranked USING(contact_id)
      LEFT JOIN home_phones_ranked USING(contact_id)
      LEFT JOIN work_phones_ranked USING(contact_id)

    WHERE
      (current_physical_addresses.physical_address_rank = 1 OR
       current_physical_addresses.physical_address_rank IS NULL)
      AND
      (current_mailing_addresses.mailing_address_rank = 1 OR current_mailing_addresses.mailing_address_rank IS NULL)
      AND
      (cell_phones_ranked.cell_phone_rank = 1 OR cell_phones_ranked.cell_phone_rank IS NULL)
      AND
      (home_phones_ranked.home_phone_rank = 1 OR home_phones_ranked.home_phone_rank IS NULL)
      AND
      (work_phones_ranked.work_phone_rank = 1 OR work_phones_ranked.work_phone_rank IS NULL)
  ),

  -- This CTE filters and ranks contacts with is_legal and without restraining_order
  legal_guardians AS (
    SELECT DISTINCT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY student_id
        ORDER BY contact_rank
      ) AS legal_guardian_rank

    FROM contact_info_one_row_per_stu_contact_pair

    WHERE
      is_legal IS TRUE AND
      (restraining_order IS FALSE OR restraining_order IS NULL)
  ),

  -- This CTE filters and ranks contacts with emergency_contact and without restraining_order and is_legal
  emergency_contacts AS (
    SELECT DISTINCT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY student_id
        ORDER BY contact_rank
      ) AS non_legal_emergency_contact_rank

    FROM contact_info_one_row_per_stu_contact_pair

    WHERE
      (is_legal IS FALSE OR is_legal IS NULL ) AND
      (restraining_order IS FALSE OR restraining_order IS NULL)
      AND emergency_contact IS TRUE
  ),

/******************************************************************************
The following 4 CTEs allow us to place these legal_guardians next to each other
in a wide format.
******************************************************************************/

  legal_guardian_1 AS (
    SELECT * FROM legal_guardians WHERE legal_guardian_rank = 1
  ),

  legal_guardian_2 AS (
    SELECT * FROM legal_guardians WHERE legal_guardian_rank = 2
  ),

  -- same deal for emergency contacts
  emergency_contact_1 AS (
    SELECT * FROM emergency_contacts WHERE non_legal_emergency_contact_rank = 1
  ),

  emergency_contact_2 AS (
    SELECT * FROM emergency_contacts WHERE non_legal_emergency_contact_rank = 2
  ),

/******************************************************************************
The following CTE is the final output of the contacts query in wide format.
******************************************************************************/
  contacts_final AS (
    SELECT DISTINCT
      local_student_id,
      CASE
        WHEN sessions.site_id = 1 THEN 51
        WHEN sessions.site_id = 2 THEN 50
        WHEN sessions.site_id = 3 THEN 47
        WHEN sessions.site_id = 4 THEN 48
        WHEN sessions.site_id = 5 THEN 49
        WHEN sessions.site_id = 6 THEN 46
        WHEN sessions.site_id = 7 THEN 52
        WHEN sessions.site_id = 8 THEN 276
        WHEN sessions.site_id = 11 THEN 144
        WHEN sessions.site_id = 12 THEN 145
        WHEN sessions.site_id = 13 THEN 277
        ELSE 9999999
        END AS "site_id_sm", -- SchoolMint site ids
    
      CASE
        WHEN sessions.site_id = 1 THEN 'Summit Rainier'
        WHEN sessions.site_id = 2 THEN 'Summit Tahoma'
        WHEN sessions.site_id = 3 THEN 'Summit Prep'
        WHEN sessions.site_id = 4 THEN 'Summit Everest'
        WHEN sessions.site_id = 5 THEN 'Summit Denali'
        WHEN sessions.site_id = 6 THEN 'Summit Shasta'
        WHEN sessions.site_id = 7 THEN 'Summit K2'
        WHEN sessions.site_id = 8 THEN 'Summit Tamalpais'
        WHEN sessions.site_id = 11 THEN 'Summit Sierra'
        WHEN sessions.site_id = 12 THEN 'Summit Olympus'
        WHEN sessions.site_id = 13 THEN 'Summit Atlas'
        ELSE 'Other Site'
        END AS "site_name_sm", -- SchoolMint site names

    -- Guardian 1
      legal_guardian_1.contact_id AS "guardian_1.contact_id",
      legal_guardian_1.last_name AS "guardian_1.last_name",
      legal_guardian_1.first_name AS "guardian_1.first_name",
      legal_guardian_1.contact_type_sm AS "guardian_1.contact_type",

      legal_guardian_1.email_address AS "guardian_1.email",

      legal_guardian_1.cell_phone_number AS "guardian_1.cell_phone_number",
      legal_guardian_1.home_phone_number AS "guardian_1.home_phone_number",
      legal_guardian_1.work_phone_number AS "guardian_1.work_phone_number",

      legal_guardian_1.physical_address_line_1 AS "guardian_1.physical_address_line_1",
      legal_guardian_1.physical_address_line_2 AS "guardian_1.physical_address_line_2",
      legal_guardian_1.physical_address_city AS "guardian_1.physical_address_city",
      legal_guardian_1.physical_address_state AS "guardian_1.physical_address_state",
      legal_guardian_1.physical_address_zip AS "guardian_1.physical_address_zip",

      legal_guardian_1.mailing_address_line_1 AS "guardian_1.mailing_address_line_1",
      legal_guardian_1.mailing_address_line_2 AS "guardian_1.mailing_address_line_2",
      legal_guardian_1.mailing_address_city AS "guardian_1.mailing_address_city",
      legal_guardian_1.mailing_address_state AS "guardian_1.mailing_address_state",
      legal_guardian_1.mailing_address_zip AS "guardian_1.mailing_address_zip",

    -- Guardian 2
      legal_guardian_2.contact_id AS "guardian_2.contact_id",
      legal_guardian_2.last_name AS "guardian_2.last_name",
      legal_guardian_2.first_name AS "guardian_2.first_name",
      legal_guardian_2.contact_type_sm AS "guardian_2.contact_type",

      legal_guardian_2.email_address AS "guardian_2.email",

      legal_guardian_2.cell_phone_number AS "guardian_2.cell_phone_number",
      legal_guardian_2.home_phone_number AS "guardian_2.home_phone_number",
      legal_guardian_2.work_phone_number AS "guardian_2.work_phone_number",

      legal_guardian_2.physical_address_line_1 AS "guardian_2.physical_address_line_1",
      legal_guardian_2.physical_address_line_2 AS "guardian_2.physical_address_line_2",
      legal_guardian_2.physical_address_city AS "guardian_2.physical_address_city",
      legal_guardian_2.physical_address_state AS "guardian_2.physical_address_state",
      legal_guardian_2.physical_address_zip AS "guardian_2.physical_address_zip",

      legal_guardian_2.mailing_address_line_1 AS "guardian_2.mailing_address_line_1",
      legal_guardian_2.mailing_address_line_2 AS "guardian_2.mailing_address_line_2",
      legal_guardian_2.mailing_address_city AS "guardian_2.mailing_address_city",
      legal_guardian_2.mailing_address_state AS "guardian_2.mailing_address_state",
      legal_guardian_2.mailing_address_zip AS "guardian_2.mailing_address_zip",

    -- Emergency Contact 1
      emergency_contact_1.contact_id AS "emergency_contact_1.contact_id",
      emergency_contact_1.last_name AS "emergency_contact_1.last_name",
      emergency_contact_1.first_name AS "emergency_contact_1.first_name",
      emergency_contact_1.contact_type_sm AS "emergency_contact_1.contact_type",

      emergency_contact_1.email_address AS "emergency_contact_1.email",

      emergency_contact_1.cell_phone_number AS "emergency_contact_1.cell_phone_number",
      emergency_contact_1.home_phone_number AS "emergency_contact_1.home_phone_number",
      emergency_contact_1.home_phone_number AS "emergency_contact_1.work_phone_number",

    -- Emergency Contact 1
      emergency_contact_2.contact_id AS "emergency_contact_2.contact_id",
      emergency_contact_2.last_name AS "emergency_contact_2.last_name",
      emergency_contact_2.first_name AS "emergency_contact_2.first_name",
      emergency_contact_2.contact_type_sm AS "emergency_contact_2.contact_type",

      emergency_contact_2.email_address AS "emergency_contact_2.email",

      emergency_contact_2.cell_phone_number AS "emergency_contact_2.cell_phone_number",
      emergency_contact_2.home_phone_number AS "emergency_contact_2.home_phone_number",
      emergency_contact_2.home_phone_number AS "emergency_contact_2.work_phone_number"

    FROM student_session_aff AS enrollments
      LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
      LEFT JOIN public.students stud USING(student_id)

      LEFT JOIN legal_guardian_1 ON legal_guardian_1.student_id = enrollments.student_id
      LEFT JOIN legal_guardian_2 ON legal_guardian_2.student_id = enrollments.student_id
      LEFT JOIN emergency_contact_1 ON emergency_contact_1.student_id = enrollments.student_id
      LEFT JOIN emergency_contact_2 ON emergency_contact_2.student_id = enrollments.student_id

    WHERE
      -- Get students enrolled in the current academic year
      sessions.academic_year = 2019

      -- Get students enrolled in a window around the current time
      AND enrollments.entry_date <= current_date
      AND (enrollments.leave_date > current_date OR enrollments.leave_date = NULL)

      -- Get rid of the district 'Summit Public Schools', 'Summit NPS', and 'SPS Tour' site association
      AND sessions.site_id < 20

    ORDER BY local_student_id
  )

/******************************************************************************
The following is the final query that outputs the data into a format for upload
to Schoolmint.
******************************************************************************/

SELECT DISTINCT
  'true' AS account_pending_pwd_reset,
  NULL AS account_preferred_language_id,
  stud.local_student_id AS "student_sis_local_id",
  stud.student_id AS "student_sis_id",
  stud.first_name AS "student_first_name",
  stud.middle_name AS "student_middle_name",
  stud.last_name AS "student_last_name",
  to_char(stud.birth_date, 'mm/dd/yy') AS "student_birth_date",
  stud.gender AS "student_gender",

  contacts_final."guardian_1.physical_address_line_1" AS "student_address_street1",
  contacts_final."guardian_1.physical_address_line_2" AS "student_address_street2",
  contacts_final."guardian_1.physical_address_city" AS "student_address_city_name",
  contacts_final."guardian_1.physical_address_state" AS "student_address_state",
  substring(contacts_final."guardian_1.physical_address_zip" from 1 for 5) AS "student_address_zipcode",

  contacts_final.site_id_sm AS "student_current_school_id",
  contacts_final.site_name_sm AS "student_current_school_name",
  ss.grade_level_id - 1 AS "student_current_grade_level",
  ss.grade_level_id AS "re_enrollment_grade",
  contacts_final.site_id_sm AS "re_enrollment_school_id",
  contacts_final.site_name_sm AS "re_enrollment_school_name",

  contacts_final."guardian_1.contact_type" AS "student_lives_with",
  contacts_final."guardian_1.mailing_address_line_1" AS "mailing_address_street1",
  contacts_final."guardian_1.mailing_address_line_2" AS "mailing_address_street2",
  contacts_final."guardian_1.mailing_address_city" AS "mailing_address_city_name",
  contacts_final."guardian_1.mailing_address_state" AS "mailing_address_state",
  substring(contacts_final."guardian_1.mailing_address_zip" from 1 for 5) AS "mailing_address_zipcode",

  -- Guardian 1
  contacts_final."guardian_1.contact_id" AS "primary_guardian_id",
  contacts_final."guardian_1.first_name" AS "guardian_1_first_name",
  contacts_final."guardian_1.last_name" AS "guardian_1_last_name",
  contacts_final."guardian_1.email" AS "guardian_1_email",
  -- TODO I think we need to make sure the below number is populated by a number if cell is blank
  contacts_final."guardian_1.cell_phone_number" AS "guardian_1_phone_number",
  contacts_final."guardian_1.contact_type" AS "guardian_1_relation",
  contacts_final."guardian_1.physical_address_line_1" AS "guardian_1_address_street1",
  contacts_final."guardian_1.physical_address_line_2" AS "guardian_1_address_street2",
  contacts_final."guardian_1.physical_address_city" AS "guardian_1_address_city_name",
  contacts_final."guardian_1.physical_address_state" AS "guardian_1_address_state",
  substring(contacts_final."guardian_1.physical_address_zip" from 1 for 5) AS "guardian_1_address_zipcode",
  contacts_final."guardian_1.home_phone_number" AS "guardian_1_home_phone_number",
  contacts_final."guardian_1.work_phone_number" AS "guardian_1_work_phone_number",

  -- Guardian 2
  contacts_final."guardian_2.first_name" AS "guardian_2_first_name",
  contacts_final."guardian_2.last_name" AS "guardian_2_last_name",
  contacts_final."guardian_2.email" AS "guardian_2_email",
  contacts_final."guardian_2.cell_phone_number" AS "guardian_2_phone_number",
  contacts_final."guardian_2.contact_type" AS "guardian_2_relation",
  contacts_final."guardian_2.physical_address_line_1" AS "guardian_2_address_street1",
  contacts_final."guardian_2.physical_address_line_2" AS "guardian_2_address_street2",
  contacts_final."guardian_2.physical_address_city" AS "guardian_2_address_city_name",
  contacts_final."guardian_2.physical_address_state" AS "guardian_2_address_state",
  substring(contacts_final."guardian_2.physical_address_zip" from 1 for 5) AS "guardian_2_address_zipcode",
  contacts_final."guardian_2.home_phone_number" AS "guardian_2_home_phone_number",
  contacts_final."guardian_2.work_phone_number" AS "guardian_2_work_phone_number",

  -- Emergency contact 1
  contacts_final."emergency_contact_1.first_name" AS "emergency_contact_1_first_name",
  contacts_final."emergency_contact_1.last_name" AS "emergency_contact_1_last_name",
  contacts_final."emergency_contact_1.cell_phone_number" AS "emergency_contact_1_mobile_phone_number",
  contacts_final."emergency_contact_1.home_phone_number" AS "emergency_contact_1_home_phone_number",
  contacts_final."emergency_contact_1.work_phone_number" AS "emergency_contact_1_work_phone_number",
  contacts_final."emergency_contact_1.email" AS "emergency_contact_1_email",
  contacts_final."emergency_contact_1.contact_type" AS "emergency_contact_1_relationship",
  
  -- Emergency contact 2
  contacts_final."emergency_contact_2.first_name" AS "emergency_contact_2_first_name",
  contacts_final."emergency_contact_2.last_name" AS "emergency_contact_2_last_name",
  contacts_final."emergency_contact_2.cell_phone_number" AS "emergency_contact_2_mobile_phone_number",
  contacts_final."emergency_contact_2.home_phone_number" AS "emergency_contact_2_home_phone_number",
  contacts_final."emergency_contact_2.work_phone_number" AS "emergency_contact_2_work_phone_number",
  contacts_final."emergency_contact_2.email" AS "emergency_contact_2_email",
  contacts_final."emergency_contact_2.contact_type" AS "emergency_contact_2_relationship",

  -- Emergency contact 3
  NULL AS "emergency_contact_3_first_name",
  NULL AS "emergency_contact_3_last_name",
  NULL AS "emergency_contact_3_mobile_phone_number",
  NULL AS "emergency_contact_3_home_phone_number",
  NULL AS "emergency_contact_3_work_phone_number",
  NULL AS "emergency_contact_3_email",
  NULL AS "emergency_contact_3_relationship",

  health.general.doctor_name AS "student_doctor_name",
  health.general.dr_phone AS "student_doctor_number"


FROM
  matviews.ss_current AS ss
  LEFT JOIN public.students stud USING (student_id)
  -- Contact info from contacts query
  LEFT JOIN contacts_final ON contacts_final.local_student_id = stud.local_student_id
  -- Health information for Doctor
  LEFT JOIN health.general ON stud.student_id = health.general.student_id

WHERE
  ss.site_id < 20 AND
  ss.grade_level_id <> 13

ORDER BY stud.local_student_id