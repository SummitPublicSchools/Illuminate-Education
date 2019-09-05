/*************************************************************************
* sed_students - NOT FINAL
**************************************************************************
* Original Author: Maddy Landon
* Last Updated: 2018-03-23
*
* Description:
* In Illuminate, a student is flagged as Socio-Economically Disadvantaged (SED) when the student meets either one of two criteria:
* 1.  A student's parent education level has been marked as "Not a high school graduate"
* OR
* 2. The student has a free or reduced lunch program record with a start date within the current academic year.
*
* This query calculates an "is_sed" field for currently enrolled students.
*
* Ideas for Extension
*  This query is a useful to add demographic information to individual student level reports because in comparison to FRL status,
* SED flags are less sensitive and can be shared at the student level with a wider audience
*/

with frl AS (
    SELECT
      enrollments.student_id,
      programs.student_program_id,
      programs.start_date,
      programs.end_date
    FROM student_session_aff AS enrollments
      -- only join current programs
    LEFT JOIN student_program_aff programs ON (enrollments.student_id = programs.student_id
                                                 AND programs.end_date >= CURRENT_DATE)
    LEFT JOIN codes.student_programs ON programs.student_program_id = student_programs.code_id
    LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
    -- filter for FRL programs only

    WHERE student_programs.code_key in ('137', '136')
    AND academic_year = 2018
),
  parent_ed AS (
    SELECT
      student_id,
      parent_education.code_translation AS parent_ed_level
    FROM students
    LEFT JOIN codes.parent_education ON students.parent_education_level = parent_education.code_id

    WHERE code_translation LIKE 'Not a High School Graduate'
),
  sed AS(
    SELECT
      student_id
    FROM frl
    UNION
    SELECT
      student_id
    FROM parent_ed
),
  current_house AS (
    SELECT DISTINCT
      enrollments.student_id,
      house_name,
      enrollments.session_id
      FROM student_session_aff AS enrollments
      LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
      LEFT JOIN student_house_aff ON (enrollments.student_id = student_house_aff.student_id
                                        AND student_house_aff.session_id = enrollments.session_id)
      LEFT JOIN houses ON houses.house_id = student_house_aff.house_id

      WHERE academic_year = 2018
      AND leave_date >= current_date
)

SELECT
  site_name,
  local_student_id,
  ss.student_id,
  last_name,
  first_name,
  gender,
  grade_level_id - 1                              AS grade,
  house_name,
  engprof.code_translation                        AS english_proficiency,
  race_ethnicity_combined.combined_race_ethnicity AS federal_reported_race,
  email                                           AS student_email,
  CASE WHEN
    sed.student_id IS NULL
    THEN FALSE
  ELSE TRUE
  END                                             AS is_sed

FROM matviews.ss_current ss
LEFT JOIN students stud ON ss.student_id = stud.student_id
LEFT JOIN sites ON ss.site_id = sites.site_id
LEFT JOIN codes.english_proficiency engprof ON stud.english_proficiency = engprof.code_id
LEFT JOIN race_ethnicity_combined ON ss.student_id = race_ethnicity_combined.student_id
LEFT JOIN sed ON sed.student_id = stud.student_id
LEFT JOIN current_house ON ss.student_id = current_house.student_id

WHERE ss.site_id < 9999997
ORDER BY last_name