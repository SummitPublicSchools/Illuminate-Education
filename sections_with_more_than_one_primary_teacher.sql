-------------------------------------------------------------------------
-- Sections that have more than one Primary Teacher
-- Author: Patrick Yoho
-- Date: 2017-09-15
-------------------------------------------------------------------------
-- This query pulls sections from all of Summit Public Schools in a
-- state that have more than one primary teacher. Sections should only
-- have more than one primary teacher when there is a teacher change.
-- In this case, Teacher A would have an end date of say, 9/7/17, and
-- Teacher B would have a start_date of 9/8/17.
-- We had an issue where Clever was not syncing these types of sections
-- for certain teachers on 9/15/17. If we have this again,
-- this query can help identify sections to check proactively.
-------------------------------------------------------------------------
WITH mult_teachers_assoc AS (
  SELECT
    sections.section_id,
    string_agg( DISTINCT CONCAT(users.last_name, users.first_name), '; ') AS teachers

  FROM
    sections

  LEFT JOIN section_teacher_aff on sections.section_id = section_teacher_aff.section_id
  LEFT JOIN users on section_teacher_aff.user_id = users.user_id
  LEFT JOIN section_term_aff on sections.section_id = section_term_aff.section_id
  LEFT JOIN terms on section_term_aff.term_id = terms.term_id
  LEFT JOIN sessions on terms.session_id = sessions.session_id
  LEFT JOIN sites on sessions.site_id = sites.site_id
  LEFT JOIN section_timeblock_aff on sections.section_id = section_timeblock_aff.section_id
  LEFT JOIN timeblocks on section_timeblock_aff.timeblock_id = timeblocks.timeblock_id

  WHERE
    sessions.academic_year = 2018 AND
    section_teacher_aff.primary_teacher IS TRUE

  GROUP BY sections.section_id
)

SELECT
  sections.section_id,
  sites.site_name,
  courses.school_course_id,
  sections.local_section_id,
  courses.short_name,
  CONCAT(users.last_name, users.first_name),
  users.local_user_id,
  section_teacher_aff.start_date,
  section_teacher_aff.end_date,
  timeblocks.timeblock_name,
  mult_teachers_assoc.teachers

FROM
  sections

  LEFT JOIN section_teacher_aff on sections.section_id = section_teacher_aff.section_id
  LEFT JOIN users on section_teacher_aff.user_id = users.user_id
  LEFT JOIN section_course_aff on sections.section_id = section_course_aff.section_id
  LEFT JOIN courses on section_course_aff.course_id = courses.course_id
  LEFT JOIN section_term_aff on sections.section_id = section_term_aff.section_id
  LEFT JOIN terms on section_term_aff.term_id = terms.term_id
  LEFT JOIN sessions on terms.session_id = sessions.session_id
  LEFT JOIN sites on sessions.site_id = sites.site_id
  LEFT JOIN section_timeblock_aff on sections.section_id = section_timeblock_aff.section_id
  LEFT JOIN timeblocks on section_timeblock_aff.timeblock_id = timeblocks.timeblock_id
  LEFT JOIN mult_teachers_assoc ON mult_teachers_assoc.section_id = sections.section_id

WHERE
  sessions.academic_year = 2018 AND
  teachers LIKE '%' || ';' || '%' -- only include sections that have multiple primary teachers
  -- these next two are optional ways to filter what is returned from this query
  --section_teacher_aff.end_date < date('2017-09-30') AND
  -- sites.site_name = 'Summit Public School: K2' AND
