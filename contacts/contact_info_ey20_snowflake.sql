WITH
	contact_types_ranked AS (
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
      FROM MAIN.ILLUMINATE_CA.CONTACTS_STUDENTS_CONTACT_INFO_LATEST
    ),

	contacts_ranked AS (
	    SELECT
	    c_types_ranked.*,
	    codes_language.code_translation AS correspondance_language_text,
	    codes_parent_education.code_translation AS education_level_text,
	    codes_marital_status.code_translation AS maritial_status_text,
	    ROW_NUMBER() OVER (
	      PARTITION BY student_id
	      ORDER BY
	        (CASE WHEN primary_household = true THEN 1 WHEN primary_household IS NULL THEN 2 ELSE 3 END),
	        (CASE WHEN primary_contact =true THEN 1 WHEN primary_contact IS NULL THEN 2 ELSE 3 END),
	        (CASE WHEN resides_with =true THEN 1 WHEN resides_with IS NULL THEN 2 ELSE 3 END),
	        (CASE WHEN is_legal =true THEN 1 WHEN is_legal IS NULL THEN 2 ELSE 3 END)
	    ) AS contact_rank
	    FROM
	    contact_types_ranked c_types_ranked
	    LEFT JOIN MAIN.ILLUMINATE_CA.CODES_LANGUAGE_LATEST codes_language ON correspondance_language_id = codes_language.code_id
	    LEFT JOIN MAIN.ILLUMINATE_CA.CODES_PARENT_EDUCATION_LATEST codes_parent_education ON education_level_id = codes_parent_education.code_id
	    LEFT JOIN MAIN.ILLUMINATE_CA.CODES_MARITAL_STATUS_LATEST codes_marital_status ON marital_status_id = codes_marital_status.code_id
	  ),

	addresses_ranked AS (
	    SELECT DISTINCT
	      contact_id,
	      dwelling_id,
	      address,
	      address_2,
	      city,
	      codes_states.code_key AS state,
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
	    FROM MAIN.ILLUMINATE_CA.CONTACTS_STUDENTS_CONTACT_INFO_LATEST
	      LEFT JOIN MAIN.ILLUMINATE_CA.CONTACTS_HOUSEHOLD_DWELLING_AFF_LATEST hda USING (household_id)
	      LEFT JOIN MAIN.ILLUMINATE_CA.CONTACTS_DWELLINGS_LATEST contacts_dweling USING (dwelling_id)
	      LEFT JOIN MAIN.ILLUMINATE_CA.CODES_STATES_LATEST codes_states ON contacts_dweling.state = codes_states.code_id
	    ORDER BY household_id, contact_id, dwelling_rank
	  ),
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
	      is_primary_dwelling,
	      is_mailing_dwelling,
	      ROW_NUMBER()
	        OVER (
	          PARTITION BY contact_id, household_id
	          ORDER BY movein_date DESC
	        ) AS physical_address_rank
	    FROM addresses_ranked
	    WHERE
	      (is_primary_dwelling = true AND is_mailing_dwelling =true) OR
	      is_mailing_dwelling =true AND
	      moveout_date is NULL
	  ),
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
	      WHERE is_mailing_dwelling = true
	      AND moveout_date IS NULL
	  ),
	  phones_ranked AS (
	  SELECT DISTINCT
	      contacts_contact_phones.contact_id AS contact_id,
	      contacts_contact_phones.phone      AS phone_number,
	      codes_phone_type.code_translation  AS phone_type,
	      contacts_contact_phones.is_primary,
	      rank()
	      OVER (PARTITION BY contact_id, phone_type_id
	        ORDER BY is_primary DESC, phone DESC)        AS phone_rank
	    FROM MAIN.ILLUMINATE_CA.CONTACTS_CONTACT_PHONES_LATEST contacts_contact_phones
	      LEFT JOIN MAIN.ILLUMINATE_CA.CODES_PHONE_TYPE_LATEST codes_phone_type

	        ON contacts_contact_phones.phone_type_id = codes_phone_type.code_id
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
  contact_info_one_row_per_stu_contact_pair AS (
    SELECT DISTINCT*

    FROM
      contacts_ranked
      LEFT JOIN MAIN.ILLUMINATE_CA.CONTACTS_CONTACTS_LATEST USING(contact_id)
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
	  legal_guardians AS (
	    SELECT DISTINCT
	      *,
	      ROW_NUMBER() OVER (
	        PARTITION BY student_id
	        ORDER BY contact_rank
	      ) AS legal_guardian_rank

	    FROM contact_info_one_row_per_stu_contact_pair

	    WHERE
	      is_legal = true AND
	      (restraining_order = false  OR restraining_order IS NULL)
	  ),
	  emergency_contacts AS (
	    SELECT DISTINCT
	      *,
	      ROW_NUMBER() OVER (
	        PARTITION BY student_id
	        ORDER BY contact_rank
	      ) AS non_legal_emergency_contact_rank

	    FROM contact_info_one_row_per_stu_contact_pair

	    WHERE
	      (is_legal = false OR is_legal is NULL ) AND
	      (restraining_order = false OR restraining_order IS NULL)
	      AND emergency_contact = true
	  ),

	  legal_guardian_1 AS (
	    SELECT * FROM legal_guardians WHERE legal_guardian_rank = 1
	  ),

	  legal_guardian_2 AS (
	    SELECT * FROM legal_guardians WHERE legal_guardian_rank = 2
	  ),

	  emergency_contact_1 AS (
	    SELECT * FROM emergency_contacts WHERE non_legal_emergency_contact_rank = 1
	  ),

	  emergency_contact_2 AS (
	    SELECT * FROM emergency_contacts WHERE non_legal_emergency_contact_rank = 2
	  )

SELECT DISTINCT
  local_student_id,

-- Guardian 1
  legal_guardian_1.contact_id AS "guardian_1.contact_id",
  legal_guardian_1.last_name AS "guardian_1.last_name",
  legal_guardian_1.first_name AS "guardian_1.first_name",
  legal_guardian_1.contact_type AS "guardian_1.contact_type",

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
  legal_guardian_2.contact_type AS "guardian_2.contact_type",

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
  emergency_contact_1.contact_type AS "emergency_contact_1.contact_type",

  emergency_contact_1.email_address AS "emergency_contact_1.email",

  emergency_contact_1.cell_phone_number AS "emergency_contact_1.cell_phone_number",
  emergency_contact_1.home_phone_number AS "emergency_contact_1.home_phone_number",
  emergency_contact_1.work_phone_number AS "emergency_contact_1.work_phone_number",

-- Emergency Contact 1
  emergency_contact_2.contact_id AS "emergency_contact_2.contact_id",
  emergency_contact_2.last_name AS "emergency_contact_2.last_name",
  emergency_contact_2.first_name AS "emergency_contact_2.first_name",
  emergency_contact_2.contact_type AS "emergency_contact_2.contact_type",

  emergency_contact_2.email_address AS "emergency_contact_2.email",

  emergency_contact_2.cell_phone_number AS "emergency_contact_2.cell_phone_number",
  emergency_contact_2.home_phone_number AS "emergency_contact_2.home_phone_number",
  emergency_contact_2.work_phone_number AS "emergency_contact_2.work_phone_number"

FROM MAIN.ILLUMINATE_CA.PUBLIC_STUDENT_SESSION_AFF_LATEST AS enrollments
  LEFT JOIN MAIN.ILLUMINATE_CA.PUBLIC_SESSIONS_LATEST sessions ON enrollments.session_id = sessions.session_id

  LEFT JOIN MAIN.ILLUMINATE_CA.PUBLIC_STUDENTS_LATEST stud USING(student_id)

  LEFT JOIN legal_guardian_1 ON legal_guardian_1.student_id = enrollments.student_id
  LEFT JOIN legal_guardian_2 ON legal_guardian_2.student_id = enrollments.student_id
  LEFT JOIN emergency_contact_1 ON emergency_contact_1.student_id = enrollments.student_id
  LEFT JOIN emergency_contact_2 ON emergency_contact_2.student_id = enrollments.student_id

WHERE
  -- get students enrolled in the current academic year
  sessions.academic_year = 2020

  -- get students enrolled in a window around the current time
  AND enrollments.entry_date >= CURRENT_DATE
  AND enrollments.leave_date > CURRENT_DATE



  -- get rid of the district 'Summit Public Schools' site association
  AND sessions.site_id < 20

ORDER BY local_student_id
