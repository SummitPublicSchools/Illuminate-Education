/******************************************************************************
* Splintered from contact_info_starter-long_or_wide.sql
*
*
* Sent to Illuminate to make a custom report on 2019-08-08.
*******************************************************************************/


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
###############################################################################
 YOU MAY EDIT THE SQL BELOW THIS BLOCK
###############################################################################
 Want Long Data (Multiple rows per student, one contact per row)?
  Query from contact_info_one_row_per_stu_contact_pair and make sure you
  filter out anyone who has a restraining_order flag set!

 Want Wide Data (One row per student)?
  Make additional CTEs that filter on legal_guardian_rank or
  emergency_contact_rank (example: legal_guardian_1 below).
  *The rest of this example query shows how to do this.*
******************************************************************************/

  -- The following two CTEs allow us to place these legal_guardians next to each other in a wide format
  --  Adding additional CTEs like this will allow you to choose to display more legal guardians
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
  )

SELECT DISTINCT
  local_student_id AS "Student Sis Local Id",
  sessions.site_id AS "Site Id",
  stud.student_id AS "Student Sis Id",
  houses.house_name AS "Mentor",
  stud.first_name AS "Student First Name",
  stud.last_name AS "Student Last Name",
  enrollments.grade_level_id - 1 AS "Grade",
  stud.gender AS "Student Gender",
  lang_codes.code_translation AS "Language",

-- Guardian 1
  legal_guardian_1.contact_id AS "Primary Guardian Id",
  legal_guardian_1.first_name AS "Guardian 1 First Name",
  legal_guardian_1.last_name AS "Guardian 1 Last Name",
  legal_guardian_1.email_address AS "Guardian 1 Email",
  legal_guardian_1.cell_phone_number AS "Guardian 1 Phone Number",
  legal_guardian_1.contact_type AS "Guardian 1 Relation",
  legal_guardian_1.home_phone_number AS "Guardian 1 Home Phone Number",

-- Guardian 2
  legal_guardian_2.first_name AS "Guardian 2 First Name",
  legal_guardian_2.last_name AS "Guardian 2 Last Name",
  legal_guardian_2.email_address AS "Guardian 2 Email",
  legal_guardian_2.cell_phone_number AS "Guardian 2 Phone Number",
  legal_guardian_2.contact_type AS "Guardian 2 Relation",
  legal_guardian_2.home_phone_number AS "Guardian 2 Home Phone Number",

-- Emergency Contact 1
  emergency_contact_1.first_name AS "Emergency Contact 1 First Name",
  emergency_contact_1.last_name AS "Emergency Contact 1 Last Name",
  emergency_contact_1.cell_phone_number AS "Emergency Contact 1 Mobile Phone Number",
  emergency_contact_1.home_phone_number AS "Emergency Contact 1 Home Phone Number",
  emergency_contact_1.email_address AS "Emergency Contact 1 Email",
  emergency_contact_1.contact_type AS "Emergency Contact 1 Relationship",

-- Emergency Contact 1
  emergency_contact_2.first_name AS "Emergency Contact 2 First Name",
  emergency_contact_2.last_name AS "Emergency Contact 2 Last Name",
  emergency_contact_2.cell_phone_number AS "Emergency Contact 2 Mobile Phone Number",
  emergency_contact_2.home_phone_number AS "Emergency Contact 2 Home Phone Number",
  emergency_contact_2.email_address AS "Emergency Contact 2 Email",
  emergency_contact_2.contact_type AS "Emergency Contact 2 Relationship"

FROM student_session_aff AS enrollments
  LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
  LEFT JOIN public.students stud USING(student_id)
  LEFT JOIN student_language lang USING(student_id)
  LEFT JOIN codes.language lang_codes ON lang.home_language = lang_codes.code_id

  -- Get mentor
  LEFT JOIN student_house_aff ON stud.student_id = student_house_aff.student_id
    AND student_house_aff.session_id = sessions.session_id
  LEFT JOIN houses ON houses.house_id = student_house_aff.house_id

  LEFT JOIN legal_guardian_1 ON legal_guardian_1.student_id = enrollments.student_id
  LEFT JOIN legal_guardian_2 ON legal_guardian_2.student_id = enrollments.student_id
  LEFT JOIN emergency_contact_1 ON emergency_contact_1.student_id = enrollments.student_id
  LEFT JOIN emergency_contact_2 ON emergency_contact_2.student_id = enrollments.student_id

WHERE
  -- get students enrolled in a window around the current time
  enrollments.entry_date <= as_of_selector
  AND enrollments.leave_date >= as_of_selector

  -- get rid of the district 'Summit Public Schools' site association
  AND sessions.site_id < 20

ORDER BY local_student_id;
