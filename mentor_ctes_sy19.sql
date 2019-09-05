/***************************************************
* mentor_ctes
****************************************************
* Original Author: Patrick Yoho
* Original Date: 10/5/2018
*
* These CTEs should be able to be added to 
* another query to pull in mentor data.
*
* The student_set will filter out which students
* have their mentors pulled.
*
* The student_mentors query is specific to SY19.
*
* NOTE: You should test this to make sure its
* pulling correctly as part of your QA
*****************************************************/

WITH student_set AS (
  SELECT
    enrollments.student_id
  , enrollments.grade_level_id - 1 AS grade_level
  , sessions.academic_year
  , enrollments.entry_date
  , enrollments.leave_date
  , sessions.site_id
  FROM
    -- for selecting school year student set
    student_session_aff AS enrollments
    LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
    LEFT JOIN terms ON sessions.session_id = terms.session_id

  WHERE
    -- student set
    sessions.academic_year = 2019
    AND term_name = 'Year'
    AND sessions.site_id IN(1,2,3,4,5,6,7,8,11,12,13)
    -- Remove the following if you want all student enrollments for this academic year
    AND DATE 'today' BETWEEN enrollments.entry_date AND enrollments.leave_date

  ORDER BY student_id
), student_mentors AS (
  SELECT DISTINCT
    student_set.student_id
    , users.user_id
    , users.last_name
    , users.first_name
    , users.email1 AS email
  FROM student_set
    LEFT JOIN section_student_aff ON student_set.student_id = section_student_aff.student_id
    LEFT JOIN sections ON section_student_aff.section_id = sections.section_id
    LEFT JOIN section_teacher_aff ON sections.section_id = section_teacher_aff.section_id
    LEFT JOIN users ON section_teacher_aff.user_id = users.user_id
    LEFT JOIN courses ON section_student_aff.course_id = courses.course_id
    LEFT JOIN sites ON student_set.site_id = sites.site_id
  WHERE
    (
      (sites.site_name = 'Everest Public High School' AND courses.short_name LIKE 'Community Group')
      OR (sites.site_name = 'Summit Preparatory Charter High School' AND courses.short_name LIKE 'HCC')
      OR (sites.site_name IN ('Summit Public School: Denali', 'Summit Public School: K2',
                              'Summit Public School: Sierra')
                              AND courses.short_name LIKE 'Mentor PLT')
      OR (sites.site_name IN ('Summit Public School: Tamalpais',
                              'Summit Public School: Rainier',
                              'Summit Public School: Tahoma',
                              'Summit Public School: Shasta',
                              'Summit Public School: Atlas',
                              'Summit Public School: Olympus')
          AND courses.short_name LIKE 'Mentor Time')
    )
    AND DATE 'today' BETWEEN section_teacher_aff.start_date AND section_teacher_aff.end_date
    AND section_teacher_aff.primary_teacher IS TRUE
    AND (section_student_aff.leave_date > DATE 'today' OR section_student_aff.leave_date IS NULL)
)
