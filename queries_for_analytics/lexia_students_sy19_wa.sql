CREATE OR REPLACE VIEW illuminate.lexia_students_sy19_wa AS
WITH
session_term_filter_wa AS (
  SELECT
    sessions.session_id
    , terms.term_id

  FROM
    illuminate.wa_public_sessions AS sessions
    LEFT JOIN illuminate.wa_public_terms AS terms USING(session_id)

  WHERE
    sessions.academic_year = 2019
    AND terms.term_name = 'Year'
    -- get only regular school sites
    AND sessions.site_id < 20
    -- AND wa_public_sessions.site_id IN (7, 8)
)
, student_set_wa AS (
  SELECT
    enrollments.student_id
  , enrollments.grade_level_id - 1 AS grade_level
  , sessions.academic_year
--   , enrollments.entry_date
--   , enrollments.leave_date
  , sessions.site_id
  FROM
    -- for selecting school year student set
    illuminate.wa_public_student_session_aff AS enrollments
    LEFT JOIN illuminate.wa_public_sessions AS sessions
      ON enrollments.session_id = sessions.session_id
    LEFT JOIN illuminate.wa_public_terms AS terms
        ON sessions.session_id = terms.session_id

  WHERE
    -- student set
    sessions.academic_year = 2019
    AND term_name = 'Year'
    AND sessions.site_id IN(1,2,3,4,5,6,7,8,11,12,13)
    -- Remove the following if you want all student enrollments for this academic year
    AND NOW()::DATE BETWEEN enrollments.entry_date AND enrollments.leave_date

  ORDER BY student_id
)

, student_mentors_wa AS (
    SELECT
    student_set_wa.student_id
    , users.user_id
    , users.last_name
    , users.first_name
    , LOWER(users.email1) AS email
  FROM student_set_wa
    LEFT JOIN illuminate.wa_public_section_student_aff AS section_student_aff
      ON student_set_wa.student_id = section_student_aff.student_id
    LEFT JOIN illuminate.wa_public_sections AS sections
      ON section_student_aff.section_id = sections.section_id
    LEFT JOIN illuminate.wa_public_section_teacher_aff AS section_teacher_aff
      ON sections.section_id = section_teacher_aff.section_id
    LEFT JOIN illuminate.wa_public_users AS users
      ON section_teacher_aff.user_id = users.user_id
    LEFT JOIN illuminate.wa_public_courses AS courses
      ON section_student_aff.course_id = courses.course_id
    LEFT JOIN illuminate.wa_public_sites AS sites
      ON student_set_wa.site_id = sites.site_id
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

SELECT DISTINCT
  CAST(students.local_student_id AS INT) AS local_student_id
  , students.last_name
  , students.first_name
  , sites.site_name
  , student_set_wa.grade_level
  , student_mentors_wa.last_name AS mentor_last_name
  , student_mentors_wa.first_name AS mentor_first_name
  , student_mentors_wa.user_id AS mentor_user_id
  , student_mentors_wa.email AS mentor_email
  --, sections.section_id
  --, SUBSTRING(timeblocks.timeblock_name,4,3) AS timeblock
  , courses.short_name
  , users.last_name AS section_teacher_last_name
  , users.first_name AS section_teacher_first_name
  , users.user_id AS section_teacher_user_id
  , LOWER(users.email1) AS section_teacher_email


FROM student_set_wa
  LEFT JOIN illuminate.wa_public_students AS students
    ON student_set_wa.student_id = students.student_id
  LEFT JOIN illuminate.wa_public_section_student_aff AS section_student_aff
    ON student_set_wa.student_id = section_student_aff.student_id
  LEFT JOIN illuminate.wa_public_sections AS sections
    ON section_student_aff.section_id = sections.section_id
  LEFT JOIN illuminate.wa_public_section_term_aff AS section_term_aff
    ON sections.section_id = section_term_aff.section_id
  LEFT JOIN illuminate.wa_public_section_teacher_aff AS section_teacher_aff
    ON sections.section_id = section_teacher_aff.section_id
  LEFT JOIN illuminate.wa_public_users AS users
    ON section_teacher_aff.user_id = users.user_id
  LEFT JOIN illuminate.wa_public_section_timeblock_aff AS section_timeblock_aff
    ON sections.section_id = section_timeblock_aff.section_id
  LEFT JOIN illuminate.wa_public_timeblocks AS timeblocks
    ON section_timeblock_aff.timeblock_id = timeblocks.timeblock_id
  LEFT JOIN illuminate.wa_public_section_course_aff AS section_course_aff
    ON sections.section_id = section_course_aff.section_id
  LEFT JOIN illuminate.wa_public_courses AS courses
    ON section_course_aff.course_id = courses.course_id
  LEFT JOIN student_mentors_wa
    ON student_set_wa.student_id = student_mentors_wa.student_id
  LEFT JOIN illuminate.wa_public_sites AS sites
    ON student_set_wa.site_id = sites.site_id

WHERE
  -- current schedule only, update term_id for desired site
  section_term_aff.term_id IN (SELECT term_id FROM session_term_filter_wa)
  AND (section_student_aff.leave_date IS NULL OR
       NOW()::DATE BETWEEN section_student_aff.entry_date AND section_student_aff.leave_date)
  -- current primary teachers only
  AND section_teacher_aff.primary_teacher IS TRUE
  AND (section_teacher_aff.end_date IS NULL OR
       NOW()::DATE BETWEEN section_teacher_aff.start_date AND section_teacher_aff.end_date)
  -- only get reads and solves sections
  AND (
    (
      sites.site_name IN ('Summit Public School: Atlas')
      AND (
        (courses.short_name LIKE '%Reads L2%' AND courses.short_name LIKE '%6th%')
        OR
        (courses.short_name LIKE '%Reads L2%' AND courses.short_name LIKE '%7th%')
        OR
        (courses.short_name LIKE '%Reads L3%' AND courses.short_name LIKE '%6th%')
        OR
        (courses.short_name LIKE '%Reads L3%' AND courses.short_name LIKE '%7th%')
        OR
        (courses.short_name LIKE '%Reads L4%' AND courses.short_name LIKE '%6th%')
        OR
        (courses.short_name LIKE '%Reads L4%' AND courses.short_name LIKE '%7th%')
        OR
        (courses.short_name LIKE '%Reads L4-9th%')
      )
    )
   OR
    (
      sites.site_name IN ('Summit Public School: Olympus')
      AND courses.short_name LIKE '%Reads%'
    )
   OR
    (
      sites.site_name IN ('Summit Public School: Sierra')
      AND courses.short_name LIKE '%Reads L3%'
    )
  )