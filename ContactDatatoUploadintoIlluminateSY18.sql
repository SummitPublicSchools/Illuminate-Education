WITH
  parent_guardian_1 AS (
  SELECT DISTINCT
      ss.student_id,
      stud.local_student_id,
      contacts.contact_id AS primary_guardian_id,
      contacts.first_name AS guardian_1_first_name,
      contacts.last_name AS guardian_1_last_name,
      contacts.email_address AS guardian_1_email,
      cell_phone_numbers.phone_number AS guardian_1_phone_number,
      CASE
        WHEN (sct.code_translation = 'Mother' OR
             sct.code_translation = 'Father' OR
             sct.code_translation = 'Aunt' OR
             sct.code_translation = 'Uncle') THEN sct.code_translation
        WHEN (sct.code_translation = 'Court Guardian' OR
             sct.code_translation = 'Foster Father' OR
             sct.code_translation = 'Foster Mother') THEN 'Guardian'
        WHEN (sct.code_translation = 'Brother' OR
             sct.code_translation = 'Sister') THEN 'Sibling'
        ELSE 'Other'
        END AS guardian_1_relation,
        dwell.address AS guardian_1_address_street1,
        dwell.address_2 AS guardian_1_address_street2,
        dwell.city AS guardian_1_address_city_name,
        codes.states.code_key AS guardian_1_address_state,
        dwell.zip AS guardian_1_address_zipcode,
        home_phone_numbers.phone_number AS guardian_1_home_phone_number,
        work_phone_numbers.phone_number AS guardian_1_work_phone_number

    FROM
      -- all current students
      matviews.ss_current AS ss

      -- info about each student
      LEFT JOIN public.students stud
        ON ss.student_id = stud.student_id

      -- get the basic view of student contact info
      LEFT JOIN contacts.students_contact_info stu_cont_info
        ON ss.student_id = stu_cont_info.student_id

      -- connect contact type code with its text
      LEFT JOIN codes.student_contact_type sct
        ON stu_cont_info.contact_type_id = sct.code_id

      -- connect information about each actual contact
      LEFT JOIN contacts.contacts contacts
        ON stu_cont_info.contact_id = contacts.contact_id

      LEFT JOIN contacts.household_dwelling_aff hda
        ON stu_cont_info.household_id = hda.household_id

      -- connect dwelling info to the household
      LEFT JOIN contacts.dwellings dwell
        ON hda.dwelling_id = dwell.dwelling_id

      -- get the state associated with the address
      LEFT JOIN codes.states
        ON dwell.state = codes.states.code_id

      -- Get a single cell phone number for each contact. If they have more than one,
      -- default to taking the the one that is marked 'is_primary'. Otherwise, just
      -- choose one of them and we'll then let the parent decide
      LEFT JOIN (
                  SELECT *
                  FROM (
                    SELECT DISTINCT
                      contacts.contact_phones.contact_id AS contact_id,
                      contacts.contact_phones.phone      AS phone_number,
                      codes.phone_type.code_translation  AS phone_type,
                      contacts.contact_phones.is_primary,
                      rank()
                      OVER (PARTITION BY contact_id
                        ORDER BY is_primary, phone DESC)        AS rank

                    FROM contacts.contact_phones
                      LEFT JOIN codes.phone_type
                        ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                    -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                    WHERE codes.phone_type.code_translation = 'Cellular'

                    -- ORDER BY contacts.contact_phones.is_primary DESC
                  ) ranked_phone_numbers

                  WHERE rank = 1
        ) cell_phone_numbers ON contacts.contact_id = cell_phone_numbers.contact_id

      -- Get a single home phone number for each contact. If they have more than one,
      -- default to taking the the one that is marked 'is_primary'. Otherwise, just
      -- choose one of them and we'll then let the parent decide
      LEFT JOIN (
                  SELECT *
                  FROM (
                    SELECT DISTINCT
                      contacts.contact_phones.contact_id AS contact_id,
                      contacts.contact_phones.phone      AS phone_number,
                      codes.phone_type.code_translation  AS phone_type,
                      contacts.contact_phones.is_primary,
                      rank()
                      OVER (PARTITION BY contact_id
                        ORDER BY is_primary, phone DESC)        AS rank

                    FROM contacts.contact_phones
                      LEFT JOIN codes.phone_type
                        ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                    -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                    WHERE codes.phone_type.code_translation = 'Home'

                    -- ORDER BY contacts.contact_phones.is_primary DESC
                  ) ranked_phone_numbers

                  WHERE rank = 1
        ) home_phone_numbers ON contacts.contact_id = home_phone_numbers.contact_id

      -- Get a single work phone number for each contact. If they have more than one,
      -- default to taking the the one that is marked 'is_primary'. Otherwise, just
      -- choose one of them and we'll then let the parent decide
      LEFT JOIN (
                  SELECT *
                  FROM (
                    SELECT DISTINCT
                      contacts.contact_phones.contact_id AS contact_id,
                      contacts.contact_phones.phone      AS phone_number,
                      codes.phone_type.code_translation  AS phone_type,
                      contacts.contact_phones.is_primary,
                      rank()
                      OVER (PARTITION BY contact_id
                        ORDER BY is_primary, phone DESC)        AS rank

                    FROM contacts.contact_phones
                      LEFT JOIN codes.phone_type
                        ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                    -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                    WHERE codes.phone_type.code_translation = 'Work'

                    -- ORDER BY contacts.contact_phones.is_primary DESC
                  ) ranked_phone_numbers

                  WHERE rank = 1
        ) work_phone_numbers ON contacts.contact_id = work_phone_numbers.contact_id


    WHERE

    -- choose the most recent dwelling (and thus current address) for the household
    hda.is_primary IS True AND

    -- for parent/guardian 1, choose the primary parent at the student's primary
    -- household
    stu_cont_info.primary_household IS TRUE AND
    stu_cont_info.primary_contact IS TRUE AND

    -- ensure that it is a legal guardian
    stu_cont_info.is_legal IS TRUE
),
  parent_guardian_2 AS (
    SELECT *

    --Get's a single secondary parent or guardian for each current student.

    -- It chooses the single parent in this order:
    -- 1. Primary contact from secondary household
    -- 2. Secondary contact from primary household


    FROM (

        SELECT DISTINCT
          ss.student_id,
          stud.local_student_id,
          contacts.contact_id AS primary_guardian_id,
          contacts.first_name AS guardian_2_first_name,
          contacts.last_name AS guardian_2_last_name,
          contacts.email_address AS guardian_2_email,
          cell_phone_numbers.phone_number AS guardian_2_phone_number,
          CASE
            WHEN (sct.code_translation = 'Mother' OR
                 sct.code_translation = 'Father' OR
                 sct.code_translation = 'Aunt' OR
                 sct.code_translation = 'Uncle') THEN sct.code_translation
            WHEN (sct.code_translation = 'Court Guardian' OR
                 sct.code_translation = 'Foster Father' OR
                 sct.code_translation = 'Foster Mother') THEN 'Guardian'
            WHEN (sct.code_translation = 'Brother' OR
                 sct.code_translation = 'Sister') THEN 'Sibling'
            ELSE 'Other'
            END AS guardian_2_relation,
            dwell.address AS guardian_2_address_street1,
            dwell.address_2 AS guardian_2_address_street2,
            dwell.city AS guardian_2_address_city_name,
            codes.states.code_key AS guardian_2_address_state,
            dwell.zip AS guardian_2_address_zipcode,
            home_phone_numbers.phone_number AS guardian_2_home_phone_number,
            work_phone_numbers.phone_number AS guardian_2_work_phone_number,
            rank()
              OVER (PARTITION BY ss.student_id
                ORDER BY NOT stu_cont_info.primary_household,
                              stu_cont_info.primary_contact,
                              hda.movein_date DESC)        AS rank,
            stu_cont_info.primary_contact,
            stu_cont_info.primary_household,
            stu_cont_info.is_legal
            -- hda.movein_date

        FROM
          -- all current students
          matviews.ss_current AS ss

          -- info about each student
          LEFT JOIN public.students stud
            ON ss.student_id = stud.student_id

          -- get the basic view of student contact info
          LEFT JOIN contacts.students_contact_info stu_cont_info
            ON ss.student_id = stu_cont_info.student_id

          -- connect contact type code with its text
          LEFT JOIN codes.student_contact_type sct
            ON stu_cont_info.contact_type_id = sct.code_id

          -- connect information about each actual contact
          LEFT JOIN contacts.contacts contacts
            ON stu_cont_info.contact_id = contacts.contact_id

          LEFT JOIN contacts.household_dwelling_aff hda
            ON stu_cont_info.household_id = hda.household_id

          -- connect dwelling info to the household
          LEFT JOIN contacts.dwellings dwell
            ON hda.dwelling_id = dwell.dwelling_id

          -- get the state associated with the address
          LEFT JOIN codes.states
            ON dwell.state = codes.states.code_id

          -- Get a single cell phone number for each contact. If they have more than one,
          -- default to taking the the one that is marked 'is_primary'. Otherwise, just
          -- choose one of them and we'll then let the parent decide
          LEFT JOIN (
                      SELECT *
                      FROM (
                        SELECT DISTINCT
                          contacts.contact_phones.contact_id AS contact_id,
                          contacts.contact_phones.phone      AS phone_number,
                          codes.phone_type.code_translation  AS phone_type,
                          contacts.contact_phones.is_primary,
                          rank()
                          OVER (PARTITION BY contact_id
                            ORDER BY is_primary, phone DESC)        AS rank

                        FROM contacts.contact_phones
                          LEFT JOIN codes.phone_type
                            ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                        -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                        WHERE codes.phone_type.code_translation = 'Cellular'

                        -- ORDER BY contacts.contact_phones.is_primary DESC
                      ) ranked_phone_numbers

                      WHERE rank = 1
            ) cell_phone_numbers ON contacts.contact_id = cell_phone_numbers.contact_id

          -- Get a single home phone number for each contact. If they have more than one,
          -- default to taking the the one that is marked 'is_primary'. Otherwise, just
          -- choose one of them and we'll then let the parent decide
          LEFT JOIN (
                      SELECT *
                      FROM (
                        SELECT DISTINCT
                          contacts.contact_phones.contact_id AS contact_id,
                          contacts.contact_phones.phone      AS phone_number,
                          codes.phone_type.code_translation  AS phone_type,
                          contacts.contact_phones.is_primary,
                          rank()
                          OVER (PARTITION BY contact_id
                            ORDER BY is_primary, phone DESC)        AS rank

                        FROM contacts.contact_phones
                          LEFT JOIN codes.phone_type
                            ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                        -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                        WHERE codes.phone_type.code_translation = 'Home'

                        -- ORDER BY contacts.contact_phones.is_primary DESC
                      ) ranked_phone_numbers

                      WHERE rank = 1
            ) home_phone_numbers ON contacts.contact_id = home_phone_numbers.contact_id

          -- Get a single work phone number for each contact. If they have more than one,
          -- default to taking the the one that is marked 'is_primary'. Otherwise, just
          -- choose one of them and we'll then let the parent decide
          LEFT JOIN (
                      SELECT *
                      FROM (
                        SELECT DISTINCT
                          contacts.contact_phones.contact_id AS contact_id,
                          contacts.contact_phones.phone      AS phone_number,
                          codes.phone_type.code_translation  AS phone_type,
                          contacts.contact_phones.is_primary,
                          rank()
                          OVER (PARTITION BY contact_id
                            ORDER BY is_primary, phone DESC)        AS rank

                        FROM contacts.contact_phones
                          LEFT JOIN codes.phone_type
                            ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                        -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                        WHERE codes.phone_type.code_translation = 'Work'

                        -- ORDER BY contacts.contact_phones.is_primary DESC
                      ) ranked_phone_numbers

                      WHERE rank = 1
            ) work_phone_numbers ON contacts.contact_id = work_phone_numbers.contact_id


        WHERE

        -- choose the most recent dwelling (and thus current address) for the household
        hda.is_primary IS True AND

        -- for parent/guardian 1, choose the primary parent at the student's primary
        -- household
        NOT (stu_cont_info.primary_household IS TRUE AND stu_cont_info.primary_contact IS TRUE) AND

        -- ensure we are choosing legal guardians
        stu_cont_info.is_legal IS TRUE

        -- If a contact has more than one primary dwelling, take the one with the most recent move-in date
        -- (works in concordance with limit 1 in the outer query)
        -- ORDER BY hda.movein_date DESC
    ) parent_guardian_2

    WHERE rank = 1

),
  emergency_contacts AS (
    SELECT
    contact_id,
    student_id,
    local_student_id,
    emergency_contact_first_name,
    emergency_contact_last_name,
    emergency_contact_mobile_phone_number,
    emergency_contact_home_phone_number,
    emergency_contact_work_phone_number,
    emergency_contact_email,
    emergency_contact_relationship,
    row_number()
        OVER (PARTITION BY ranked_emergency_contacts.student_id
        ORDER BY ranked_emergency_contacts.rank ASC,
                 ranked_emergency_contacts.contact_id DESC) as emergency_contact_enumerator

    FROM

        (SELECT DISTINCT

            ss.student_id AS student_id,

            stud.local_student_id,
            contacts.contact_id,
            -- contacts.contact_id AS primary_guardian_id,
            contacts.first_name AS emergency_contact_first_name,
            contacts.last_name AS emergency_contact_last_name,
            cell_phone_numbers.phone_number AS emergency_contact_mobile_phone_number,
            home_phone_numbers.phone_number AS emergency_contact_home_phone_number,
            work_phone_numbers.phone_number AS emergency_contact_work_phone_number,
            contacts.email_address AS emergency_contact_email,
            students_contact_info.primary_contact,
            students_contact_info.primary_household,
            students_contact_info.emergency_contact,
            students_contact_info.is_legal,
            CASE
            WHEN (sct.code_translation = 'Mother' OR
                 sct.code_translation = 'Father' OR
                 sct.code_translation = 'Aunt' OR
                 sct.code_translation = 'Uncle') THEN sct.code_translation
            WHEN (sct.code_translation = 'Court Guardian' OR
                 sct.code_translation = 'Foster Father' OR
                 sct.code_translation = 'Foster Mother') THEN 'Guardian'
            WHEN (sct.code_translation = 'Brother' OR
                 sct.code_translation = 'Sister') THEN 'Sibling'
            ELSE 'Other'
            END AS emergency_contact_relationship,
            dense_rank()
                OVER (PARTITION BY ss.student_id
                ORDER BY students_contact_info.contact_type IS NOT NULL AND cell_phone_numbers.phone_number IS NOT NULL AND (contacts.email_address IS NOT NULL AND contacts.email_address != '') DESC,
                         students_contact_info.contact_type IS NOT NULL AND cell_phone_numbers.phone_number IS NOT NULL DESC,
                         cell_phone_numbers.phone_number IS NOT NULL DESC
                         )        AS rank

        FROM
         -- all current students
            matviews.ss_current AS ss

         -- info about each student
            LEFT JOIN public.students stud
            ON ss.student_id = stud.student_id

            -- get the basic view of student contact info
            LEFT JOIN contacts.students_contact_info -- students_contact_info
            ON ss.student_id = students_contact_info.student_id

            -- connect contact type code with its text
            LEFT JOIN codes.student_contact_type sct
            ON students_contact_info.contact_type_id = sct.code_id

            -- connect information about each actual contact
            LEFT JOIN contacts.contacts contacts
            ON students_contact_info.contact_id = contacts.contact_id

            -- Get a single cell phone number for each contact. If they have more than one,
            -- default to taking the the one that is marked 'is_primary'. Otherwise, just
            -- choose one of them and we'll then let the parent decide
            LEFT JOIN (
                      SELECT *
                      FROM (
                        SELECT DISTINCT
                          contacts.contact_phones.contact_id AS contact_id,
                          contacts.contact_phones.phone      AS phone_number,
                          codes.phone_type.code_translation  AS phone_type,
                          contacts.contact_phones.is_primary,
                          rank()
                          OVER (PARTITION BY contact_id
                            ORDER BY is_primary, phone DESC)        AS rank

                        FROM contacts.contact_phones
                          LEFT JOIN codes.phone_type
                            ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                        -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                        WHERE codes.phone_type.code_translation = 'Cellular'

                        -- ORDER BY contacts.contact_phones.is_primary DESC
                      ) ranked_phone_numbers

                      WHERE rank = 1
            ) cell_phone_numbers ON contacts.contact_id = cell_phone_numbers.contact_id

            -- Get a single home phone number for each contact. If they have more than one,
            -- default to taking the the one that is marked 'is_primary'. Otherwise, just
            -- choose one of them and we'll then let the parent decide
            LEFT JOIN (
                      SELECT *
                      FROM (
                        SELECT DISTINCT
                          contacts.contact_phones.contact_id AS contact_id,
                          contacts.contact_phones.phone      AS phone_number,
                          codes.phone_type.code_translation  AS phone_type,
                          contacts.contact_phones.is_primary,
                          rank()
                          OVER (PARTITION BY contact_id
                            ORDER BY is_primary, phone DESC)        AS rank

                        FROM contacts.contact_phones
                          LEFT JOIN codes.phone_type
                            ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                        -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                        WHERE codes.phone_type.code_translation = 'Home'

                        -- ORDER BY contacts.contact_phones.is_primary DESC
                      ) ranked_phone_numbers

                      WHERE rank = 1
            ) home_phone_numbers ON contacts.contact_id = home_phone_numbers.contact_id

            -- Get a single work phone number for each contact. If they have more than one,
            -- default to taking the the one that is marked 'is_primary'. Otherwise, just
            -- choose one of them and we'll then let the parent decide
            LEFT JOIN (
                      SELECT *
                      FROM (
                        SELECT DISTINCT
                          contacts.contact_phones.contact_id AS contact_id,
                          contacts.contact_phones.phone      AS phone_number,
                          codes.phone_type.code_translation  AS phone_type,
                          contacts.contact_phones.is_primary,
                          rank()
                          OVER (PARTITION BY contact_id
                            ORDER BY is_primary, phone DESC)        AS rank

                        FROM contacts.contact_phones
                          LEFT JOIN codes.phone_type
                            ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

                        -- phone types: 'Home, 'Work', 'Cellular', 'Other', 'Unknown
                        WHERE codes.phone_type.code_translation = 'Work'

                        -- ORDER BY contacts.contact_phones.is_primary DESC
                      ) ranked_phone_numbers

                      WHERE rank = 1
            ) work_phone_numbers ON contacts.contact_id = work_phone_numbers.contact_id

        WHERE
            students_contact_info.emergency_contact IS TRUE AND
            (students_contact_info.is_legal IS FALSE OR
            students_contact_info.is_legal IS NULL)
            -- AND stud.local_student_id = '50834'

        ORDER BY rank ) ranked_emergency_contacts

    ORDER BY emergency_contact_enumerator
  )


SELECT DISTINCT
  stud.local_student_id AS "student_sis_local_id",
  ss.site_id as site_id,
  stud.student_id AS "student_sis_id",
  stud.first_name AS "student_first_name",
  stud.last_name AS "student_last_name",
  to_char(stud.birth_date, 'mm/dd/yy') AS "student_birth_date",
  stud.gender AS "student_gender",

  stu_address.address AS "student_address_street_1",
  stu_address.address_2 AS "student_address_street_2",
  stu_address.city AS "student_address_city_name",
  stu_address.state AS "student_address_state",
  stu_address.zip AS "student_address_zipcode",

  -- TODO re_enrollment_school_id (actually, schoolmint does this)
  -- TODO student_lives_with (this will take too much time to figure out right now)
  NULL AS student_lives_with,


  stu_mail_address.address AS "mailing_address_street1",
  stu_mail_address.address_2 AS "mailing_address_street2",
  stu_mail_address.city AS "mailing_address_city_name",
  stu_mail_address.state AS "mailing_address_state",
  stu_mail_address.zip AS "mailing_address_zipcode",

  parent_guardian_1.primary_guardian_id,
  parent_guardian_1.guardian_1_first_name,
  parent_guardian_1.guardian_1_last_name,
  parent_guardian_1.guardian_1_email,
  parent_guardian_1.guardian_1_phone_number,
  parent_guardian_1.guardian_1_relation,
  parent_guardian_1.guardian_1_address_street1,
  parent_guardian_1.guardian_1_address_street2,
  parent_guardian_1.guardian_1_address_city_name,
  parent_guardian_1.guardian_1_address_state,
  parent_guardian_1.guardian_1_address_zipcode,
  parent_guardian_1.guardian_1_home_phone_number,
  parent_guardian_1.guardian_1_work_phone_number,

  parent_guardian_2.guardian_2_first_name,
  parent_guardian_2.guardian_2_last_name,
  parent_guardian_2.guardian_2_email,
  parent_guardian_2.guardian_2_phone_number,
  parent_guardian_2.guardian_2_relation,
  parent_guardian_2.guardian_2_address_street1,
  parent_guardian_2.guardian_2_address_street2,
  parent_guardian_2.guardian_2_address_city_name,
  parent_guardian_2.guardian_2_address_state,
  parent_guardian_2.guardian_2_address_zipcode,
  parent_guardian_2.guardian_2_home_phone_number,
  parent_guardian_2.guardian_2_work_phone_number,

  emergency_contact_1.emergency_contact_first_name AS emergency_contact_1_first_name,
  emergency_contact_1.emergency_contact_last_name AS emergency_contact_1_last_name,
  emergency_contact_1.emergency_contact_mobile_phone_number AS emergency_contact_1_mobile_phone_number,
  emergency_contact_1.emergency_contact_home_phone_number AS emergency_contact_1_home_phone_number,
  emergency_contact_1.emergency_contact_work_phone_number AS emergency_contact_1_work_phone_number,
  emergency_contact_1.emergency_contact_email AS emergency_contact_1_email,
  emergency_contact_1.emergency_contact_relationship AS emergency_contact_1_relationship,

  emergency_contact_2.emergency_contact_first_name AS emergency_contact_2_first_name,
  emergency_contact_2.emergency_contact_last_name AS emergency_contact_2_last_name,
  emergency_contact_2.emergency_contact_mobile_phone_number AS emergency_contact_2_mobile_phone_number,
  emergency_contact_2.emergency_contact_home_phone_number AS emergency_contact_2_home_phone_number,
  emergency_contact_2.emergency_contact_work_phone_number AS emergency_contact_2_work_phone_number,
  emergency_contact_2.emergency_contact_email AS emergency_contact_2_email,
  emergency_contact_2.emergency_contact_relationship AS emergency_contact_2_relationship

FROM
matviews.ss_current AS ss
LEFT JOIN public.students stud USING (student_id)
LEFT JOIN public.sites USING (site_id)

  -- Add student's primary address
  LEFT JOIN (SELECT student_id, address, address_2, city,
               codes.states.code_key AS state, zip
              FROM matviews.ss_current AS ss
                LEFT JOIN contacts.student_household_aff USING (student_id)
                LEFT JOIN contacts.household_dwelling_aff USING (household_id)
                LEFT JOIN contacts.dwellings USING (dwelling_id)
                -- get the state associated with the address
                LEFT JOIN codes.states
                  ON contacts.dwellings.state = codes.states.code_id

              WHERE
              ss.site_id not in (9999999, 9999998) AND
              ss.grade_level_id != 13 AND
                contacts.student_household_aff.is_primary IS TRUE AND
                contacts.household_dwelling_aff.is_primary IS TRUE
            ) stu_address USING (student_id)

  -- Add student's mailing address
  LEFT JOIN (SELECT *

              FROM (

                  SELECT
                  --local_student_id,
                  ss.student_id,
                  address,
                  address_2,
                  city,
                  codes.states.code_key AS state, zip,
                  movein_date,
                  contacts.household_dwelling_aff.is_primary,
                  row_number()
                  OVER (PARTITION BY ss.student_id
                          ORDER BY contacts.household_dwelling_aff.movein_date DESC)        AS rank

                  FROM matviews.ss_current AS ss
                  LEFT JOIN contacts.student_household_aff USING (student_id)
                  LEFT JOIN contacts.household_dwelling_aff USING (household_id)
                  LEFT JOIN contacts.dwellings USING (dwelling_id)
                  -- get the state associated with the address
                  LEFT JOIN codes.states
                    ON contacts.dwellings.state = codes.states.code_id

                  -- LEFT JOIN public.students ON ss.student_id = public.students.student_id

                  WHERE
                  ss.site_id not in (9999999, 9999998) AND
                  ss.grade_level_id != 13 AND
                  contacts.student_household_aff.is_primary IS TRUE AND
                  -- contacts.household_dwelling_aff.is_primary IS TRUE AND
                  contacts.household_dwelling_aff.is_mailing IS TRUE AND
                  contacts.household_dwelling_aff.moveout_date IS NULL
                  ) mailing_addresses

              WHERE rank = 1
            ) stu_mail_address USING (student_id)

  -- Add parent guardian 1 information
  LEFT JOIN parent_guardian_1
    ON stud.student_id = parent_guardian_1.student_id

  -- Add parent guardian 2 information
  LEFT JOIN parent_guardian_2
    ON stud.student_id = parent_guardian_2.student_id

  -- Add emergency contact 1 information
  LEFT JOIN (
    SELECT * FROM emergency_contacts WHERE emergency_contacts.emergency_contact_enumerator = 1
  ) emergency_contact_1
    ON stud.student_id = emergency_contact_1.student_id

  -- Add emergency contact 1 information
  LEFT JOIN (
    SELECT * FROM emergency_contacts WHERE emergency_contacts.emergency_contact_enumerator = 2
  ) emergency_contact_2
    ON stud.student_id = emergency_contact_2.student_id

  -- Add emergency contact 1 information
  LEFT JOIN (
    SELECT * FROM emergency_contacts WHERE emergency_contacts.emergency_contact_enumerator = 3
  ) emergency_contact_3
    ON stud.student_id = emergency_contact_3.student_id

  -- Health infromation for Doctor
  LEFT JOIN health.general
    ON stud.student_id = health.general.student_id

WHERE
ss.site_id not in (9999999, 9999998) AND
ss.grade_level_id != 13

ORDER BY stud.local_student_id