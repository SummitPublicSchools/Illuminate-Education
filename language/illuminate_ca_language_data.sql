-- Refer to Language Crosswalk
-- https://docs.google.com/spreadsheets/d/13gu2fhotgmUxtlbVN114PGVur8d1j7cVRcsK946gwvM/edit#gid=1370282296

SELECT
  local_student_id

  , english_prof.code_key AS english_proficiency_code
  , english_prof.code_translation AS english_proficiency_desc
  , stu._english_proficiency_date

  , lang.lep_date
  , lang.fep_date

  , lang.redesignation_date

  , lang.redesignation_denied
  , lang.redesignation_denied_by

  , lang.one_year_follow_up_date
  , lang.two_year_follow_up_date
  , lang.three_year_follow_up_date
  , lang.four_year_follow_up_date
  , lang.five_year_follow_up_date

  , lang.us_entry_date
  , lang.us_school_entry_date

  , lang.el_instruction_type

  , prim_lang.code_key AS primary_language_code
  , prim_lang.code_translation AS primary_language

  , corr_lang.code_key AS correspondence_language_code
  , corr_lang.code_translation AS correspondence_language

  , first_lang.code_key AS first_language_code
  , first_lang.code_translation AS first_language

  , adult_lang.code_key AS adult_language_code
  , adult_lang.code_translation AS adult_language

  , home_lang.code_key AS home_language_code
  , home_lang.code_translation AS home_language

FROM students stu
  LEFT JOIN codes.english_proficiency english_prof
    ON stu.english_proficiency = english_prof.code_id
  LEFT JOIN student_language AS lang
    ON stu.student_id = lang.student_id
  LEFT JOIN codes.language AS corr_lang
    ON stu.correspondence_language = corr_lang.code_id
  LEFT JOIN codes.language AS first_lang
    ON lang.first_language = first_lang.code_id
  LEFT JOIN codes.language AS prim_lang
    ON stu.primary_language = prim_lang.code_id
  LEFT JOIN codes.language AS adult_lang
    ON lang.adult_language = adult_lang.code_id
  LEFT JOIN codes.language AS home_lang
    ON lang.home_language = home_lang.code_id