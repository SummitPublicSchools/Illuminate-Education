/******************************************************************************
* platform_parent_login.sql
*******************************************************************************
* Original Author: Patrick Yoho
* Modified: Mario Palmisano
* Last Updated: 08/05/18
*
* This query is based on Patrick's contact_info_starter-long_or_wide.sql.  Refer to 
* documentation in that query for full details.  This query is used in preparation for
* the Platform parent login upload.  To see documentation on the upload specs check here:
* https://docs.google.com/document/d/1AGViOPUmOdlOFwxzM2gvUnO6pX8kmpKOLYEICgrkhlw/edit?ts=5b63506d#heading=h.wvqbef6rhpgz
*
* All contacts should show up regardless of if they are missing data insert in
* a selected field.
*
* There are descriptions below for how this query chooses addresses and
* phone numbers as well as specific caveats for how it ranks guardians. This
* ranking information is particularly useful for pulling together
* contact information in wide form:
*
* Addresses:
* It should include the most recent physical and mailing address. It does
* this by ranking the address by movein_date and then selecting the
* address with the top ranking, making sure that the moveout_date is null
* (meaning it is the current address).
*
* Phone Numbers:
* A contact in Illuminate can have an unlimited amount of phone numbers
* across five or more categories. We look at the cell, home, and work
* categories. If there is more than one number in this category, we
* choose the one that is primary first. If there is no primary flag
* associated with that number, then we choose a number arbitrarily based
* off of the characters in the phone number from least to greatest.
*
* Wide Queries
* When putting this data together in a wide query, we would typically
* choose to include the information for two legal_guardians and two
* emergency_contacts. Here is how we choose these contacts:
*
* 1. Legal Guardian #1
*  This is typically the primary contact at the primary household unless
*  the contact in that position is not marked as is_legal, which should not
*  be the case. The student must reside at this household for this person
*  to show up correctly.
* 2. Legal Guardian #2
*  This contact should be either the primary is_legal contact at a non-primary
*  household or a non-primary is_legal contact at the primary household.
*  There may be edge cases that cause this to be something else.
*  In the case where there are multiple contacts who could be
*  considered (e.g. more than one non-primary legal guardian in a primary
*  household), we choose the contact by a ranking of the contact
*  relationship, as defined in the CASE statement around line 100.
*  The student must reside at this household for this person
*  to show up correctly.
*
* 3. Emergency Contact #1
* 4. Emergency Contact #2
* Both emergency contacts are contacts where is_legal is not marked and
* emergency_contact is marked. Contact 1 vs. Contact 2 is chosen based
* off of the ranking based on the relationship with the student.
*
* No contacts with the restraining_order flag will show up in this query.
*
* Contacts are ranked in order of importance by their contact_type
* (i.e. relationship to the student). The order that these were ranked was
* informed by the number of legal guardians we had in each one of those
* relationships.
*
******************************************************************************/



/******************************************************************************
###############################################################################
 DON'T CHANGE ANYTHING BELOW THIS UNTIL AFTER YOU SEE THIS BLOCK AGAIN BELOW
###############################################################################
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
            ROW_NUMBER()
            OVER (PARTITION BY contact_id
              ORDER BY
                (CASE WHEN codes.phone_type.code_translation = 'Cellular' AND is_primary THEN 1
                      WHEN codes.phone_type.code_translation = 'Cellular' THEN 2
                      WHEN codes.phone_type.code_translation = 'Other' AND is_primary THEN 3
                      WHEN codes.phone_type.code_translation = 'Other' THEN 4
                      WHEN codes.phone_type.code_translation = 'Unknown' AND is_primary THEN 5
                      WHEN codes.phone_type.code_translation = 'Unknown' THEN 6
                      WHEN codes.phone_type.code_translation = 'Home' AND is_primary THEN 7
                      WHEN codes.phone_type.code_translation = 'Home' THEN 8
                      WHEN codes.phone_type.code_translation = 'Work' AND is_primary THEN 9
                      WHEN codes.phone_type.code_translation = 'Work' THEN 10
                      ELSE 11
                 END)
            ) AS phone_rank
          FROM contacts.contact_phones
            LEFT JOIN codes.phone_type
              ON contacts.contact_phones.phone_type_id = codes.phone_type.code_id

          ORDER BY contact_id, phone_rank
  ),

/*********************************
FULL SET OF CONTACT INFO AND SEPARATION INTO LEGAL AND EMERGENCY
Only grab the most current physical and mail addresses and
the top-ranked phone numbers. At this point, this will
give us all of the contact info in LONG form
*********************************/
  contact_info_one_row_per_stu_contact_pair AS (
    SELECT DISTINCT *

    FROM
      contacts_ranked
      LEFT JOIN contacts.contacts USING(contact_id)
      LEFT JOIN current_physical_addresses
        ON contacts_ranked.contact_id = current_physical_addresses.physical_addresses_contact_id AND
           contacts_ranked.household_id = current_physical_addresses.physical_addresses_household_id
      LEFT JOIN current_mailing_addresses
        ON contacts_ranked.contact_id = current_mailing_addresses.mailing_addresses_contact_id AND
           contacts_ranked.household_id = current_mailing_addresses.mailing_addresses_household_id
      LEFT JOIN phones_ranked USING(contact_id)
      
    WHERE
      (current_physical_addresses.physical_address_rank = 1 OR
       current_physical_addresses.physical_address_rank IS NULL)
      AND
      (current_mailing_addresses.mailing_address_rank = 1 OR current_mailing_addresses.mailing_address_rank IS NULL)
      AND
      (phones_ranked.phone_rank = 1 OR phones_ranked.phone_rank IS NULL)
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
      is_legal IS TRUE
      AND (restraining_order IS FALSE OR restraining_order IS NULL)
  ),
  
  first_two_legal_guardians AS (
    SELECT DISTINCT *
    
    FROM legal_guardians
    
    WHERE (legal_guardian_rank = 1 OR legal_guardian_rank = 2)
  )

    
    
/*****************************************************************
List of available fields for all contacts, similar topics grouped
 This can help you build your query outside of the CTEs below.
------------------------------------------------------------------
contact_id, student_id, household_id

last_name, first_name, middle_name, name_suffix, name_prefix,

cell_phone_number, cell_phone_is_primary
home_phone_number, home_phone_is_primary,
work_phone_number, work_phone_is_primary,

email_address, email_opt_out,

physical_address_line_1, physical_address_line_2,
physical_address_city, physical_address_state, physical_address_zip,

mailing_address_line_1,mailing_address_line_2,
mailing_address_city, mailing_address_state, mailing_address_zip,

-- Contact Relationship to Student:
contact_type, contact_type_id, contact_type_key,

-- Flags:
primary_contact,
primary_household,
resides_with,
is_legal,
emergency_contact,
receives_mailing,
restraining_order, -- we typically filter contacts with this flag out

-- Demographic Data (SPS doesn't actively collect most of these fields)
correspondance_language_text, correspondance_language_id,
birth_date,
gender,
maritial_status_text, maritial_status_text,
employer_occupation, job_title, job_address,
military, active_duty, branch_of_service

-- Contact Rankings (can be used for debugging)
contact_rank,
contact_type_rank,
legal_guardian_rank,
non_legal_emergency_contact_rank

-- Extra address fields that can be used for debugging or further joins
physical_addresses_dwelling_id,
physical_address_movein_date, physical_address_moveout_date,
physical_address_dwelling_rank

mailing_addresses_dwelling_id,
mailing_address_movein_date, mailing_address_moveout_date,
mailing_address_dwelling_rank, mailing_address_rank

****************************************************/

SELECT DISTINCT
  local_student_id AS "Local Student ID",
  stud.email AS "Student Email",
  
  first_two_legal_guardians.last_name AS "Parent Last Name",
  first_two_legal_guardians.first_name AS "Parent First Name",
  first_two_legal_guardians.email_address AS "Parent Email",
  NULL AS "Parent Username",
  first_two_legal_guardians.phone_number AS "Parent Phone Number",
  CASE WHEN first_two_legal_guardians.phone_number IS NULL THEN NULL  
       WHEN first_two_legal_guardians.phone_type = 'Cellular' THEN 'Cellular' 
       WHEN first_two_legal_guardians.phone_type = 'Home' THEN 'Home' 
       WHEN first_two_legal_guardians.phone_type = 'Work' THEN 'Work'  
       ELSE 'Other' 
  END AS "Parent Phone Type",
  CASE WHEN first_two_legal_guardians.correspondance_language_text = 'English'
            OR first_two_legal_guardians.correspondance_language_text IS NULL THEN 'English'
       WHEN first_two_legal_guardians.correspondance_language_text = 'Spanish' THEN 'Spanish'
       ELSE 'Other'
  END AS "Preferred Language"
  
FROM student_session_aff AS enrollments
  LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
  LEFT JOIN public.students AS stud USING(student_id)
  LEFT JOIN first_two_legal_guardians ON first_two_legal_guardians.student_id = enrollments.student_id

WHERE
  -- get students enrolled in a given academic year
  sessions.academic_year = {0}

  -- get students enrolled on a given day or later
  AND enrollments.entry_date >= '{1}'
  AND enrollments.leave_date > '{1}'

  -- get rid of the district 'Summit Public Schools' site association
  AND sessions.site_id < 20

ORDER BY local_student_id;
