/*
  emergency_contacts_ranked.sql
  This query will return contacts in Illuminate that:
  - Are marked as emergency_contact, but NOT legal

  It ranks the contacts such that:
  1. Contact has a relationship, cell_phone_number and email_address
  2. Contact has a relationship and cell_phone_number
  3. Contact has a cell phone number
  4. All others
*/

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

FROM (
  SELECT DISTINCT
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
    sct.code_translation as emergency_contact_relationship,
    dense_rank()
        OVER (PARTITION BY ss.student_id
        ORDER BY students_contact_info.contact_type IS NOT NULL AND cell_phone_numbers.phone_number IS NOT NULL AND (contacts.email_address IS NOT NULL AND contacts.email_address != '') DESC,
                 students_contact_info.contact_type IS NOT NULL AND cell_phone_numbers.phone_number IS NOT NULL DESC,
                 cell_phone_numbers.phone_number IS NOT NULL DESC
                 ) AS rank

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
