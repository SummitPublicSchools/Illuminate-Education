WITH
contact_types_ranked AS (
	SELECT
		student_contact_info.student_id as contact_student_id,
student_contact_info.contact_id AS person_id,
student_contact_info.contact_type AS contact_type,
student_contact_info.emergency_contact AS is_emergency,
student_contact_info.is_legal AS is_custodial,
		student_contact_info.CORRESPONDANCE_LANGUAGE_ID as correspondance_language_id,
		student_contact_info.EDUCATION_LEVEL_ID as EDUCATION_LEVEL_ID,
		student_contact_info.MARITAL_STATUS_ID as MARITAL_STATUS_ID,
		student_contact_info.PRIMARY_HOUSEHOLD as PRIMARY_HOUSEHOLD,
		student_contact_info.PRIMARY_CONTACT as PRIMARY_CONTACT,
		student_contact_info.RESIDES_WITH as RESIDES_WITH,
		student_contact_info.IS_LEGAL as IS_LEGAL,
		student_contact_info.HOUSEHOLD_ID as HOUSEHOLD_ID,

	CASE WHEN student_contact_info.contact_type = 'Mother' OR student_contact_info.contact_type = 'Father' THEN 1
			 WHEN student_contact_info.contact_type = 'Stepfather' OR contact_type = 'Stepmother' THEN 2
			 WHEN student_contact_info.contact_type = 'Aunt' OR student_contact_info.contact_type = 'Uncle' THEN 3
			 WHEN student_contact_info.contact_type = 'Grandparent' OR student_contact_info.contact_type = 'Grandmother' OR
				 student_contact_info.contact_type = 'Grandfather' THEN 4
			 WHEN student_contact_info.contact_type = 'Parent/Guardian' THEN 5
			 WHEN student_contact_info.contact_type = 'Other' THEN 6
			 WHEN student_contact_info.contact_type = 'Brother' OR student_contact_info.contact_type = 'Sister' OR
				 student_contact_info.contact_type = 'Sibling' THEN 7
			 WHEN student_contact_info.contact_type = 'Court Guardian' OR student_contact_info.contact_type = 'Caretaker' THEN 8
			 WHEN student_contact_info.contact_type = 'Foster Mother' OR contact_type = 'Foster Father' OR
				 student_contact_info.contact_type = 'Foster Parent' THEN 9
			 WHEN student_contact_info.contact_type = 'Agency Rep' THEN 10
			 WHEN student_contact_info.contact_type = 'Cousin' THEN 11
			 ELSE 12
	END AS contact_type_rank
	FROM MAIN.ILLUMINATE_CA.CONTACTS_STUDENTS_CONTACT_INFO_LATEST student_contact_info
	where contact_type is not null
),

contacts_ranked AS (
	SELECT
	c_types_ranked.*,
	codes_language.code_translation AS correspondance_language_text,
	codes_parent_education.code_translation AS education_level_text,
	codes_marital_status.code_translation AS maritial_status_text,
	ROW_NUMBER() OVER (
		PARTITION BY contact_student_id
		ORDER BY
			(CASE WHEN primary_household = true THEN 1 WHEN primary_household IS NULL THEN 2 ELSE 3 END),
			(CASE WHEN primary_contact =true THEN 1 WHEN primary_contact IS NULL THEN 2 ELSE 3 END),
			(CASE WHEN resides_with =true THEN 1 WHEN resides_with IS NULL THEN 2 ELSE 3 END),
			(CASE WHEN is_legal =true THEN 1 WHEN is_legal IS NULL THEN 2 ELSE 3 END)
	) AS contact_rank
	FROM
	contact_types_ranked c_types_ranked
	LEFT JOIN MAIN.ILLUMINATE_CA.CODES_LANGUAGE_LATEST codes_language ON c_types_ranked.correspondance_language_id = codes_language.code_id
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
)

SELECT Distinct
cr.contact_student_id AS "student_id",
cr.person_id AS "contact_id",
sites.site_name AS "site_name",
contactsList.last_name AS "last_name",
contactsList.first_name AS "first_name",
		CASE WHEN cr.contact_type = 'Grandmother' OR cr.contact_type='Grandfather' THEN 'Grandparent' else cr.contact_type END AS "contact_type",
email_address AS "email",
cell_phone_number AS "cell_phone_number",
home_phone_number AS "home_phone_number",
work_phone_number AS "work_phone_number",
	physical_address_line_1 AS "physical_address_line_1",
physical_address_line_2 AS "physical_address_line_2",
physical_address_city AS "physical_address_city",
physical_address_state AS "physical_address_state",
physical_address_zip AS "physical_address_zip",

CASE
	WHEN mailing_address_line_1 is NULL THEN
		physical_address_line_1
	ELSE
		mailing_address_line_1
	END AS "mailing_address_line_1",

CASE
	WHEN mailing_address_line_2 is NULL THEN
		physical_address_line_2
	ELSE
		mailing_address_line_2
	END AS "mailing_address_line_2",

CASE
	WHEN mailing_address_city is NULL THEN
		physical_address_city
	ELSE
		mailing_address_city
	END AS "mailing_address_city",

CASE
	WHEN mailing_address_state is NULL THEN
	physical_address_state
	ELSE
	mailing_address_state
	END AS "mailing_address_state",

CASE
	WHEN mailing_address_zip is NULL THEN
		physical_address_zip
	ELSE
		mailing_address_zip
	END AS "mailing_address_zip",

cr.is_legal AS "is_legal_guardian",
cr.contact_rank AS "guardian_ranking",
cr.is_emergency AS "is_emergency",
cr.contact_rank AS "emergency_ranking"

FROM
	MAIN.PUBLIC.STUDENTS students
	LEFT JOIN contacts_ranked cr on students.sis_student_id=cr.contact_student_id
	LEFT JOIN MAIN.PUBLIC.SITES sites on students.site_id=sites.site_id AND sites.state='CA' and sites.site_name is not null
	LEFT JOIN MAIN.ILLUMINATE_CA.CONTACTS_CONTACTS_LATEST contactsList ON contactsList.contact_id=cr.person_id
	LEFT JOIN current_physical_addresses
		ON cr.person_id = current_physical_addresses.physical_addresses_contact_id AND
			 cr.household_id = current_physical_addresses.physical_addresses_household_id AND current_physical_addresses.physical_address_rank = 1
	LEFT JOIN current_mailing_addresses
		ON cr.person_id = current_mailing_addresses.mailing_addresses_contact_id AND
			 cr.household_id = current_mailing_addresses.mailing_addresses_household_id AND current_mailing_addresses.mailing_address_rank = 1
	LEFT JOIN cell_phones_ranked cph ON cph.contact_id=cr.person_id AND cph.cell_phone_rank = 1 and cph.cell_phone_number is not NULL
	LEFT JOIN home_phones_ranked hpr ON hpr.contact_id=cr.person_id AND hpr.home_phone_rank = 1 and hpr.home_phone_number is not NULL
	LEFT JOIN work_phones_ranked wpr ON wpr.contact_id=cr.person_id AND wpr.work_phone_rank = 1 and wpr.work_phone_number is not NULL
