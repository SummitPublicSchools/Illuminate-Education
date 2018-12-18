-- All active sections w/ local IDs and local user ID.
SELECT
  sites.site_name,
  sites.site_id,
  courses.school_course_id,
  sections.local_section_id,
  courses.short_name,
  courses.school_course_id,
  rooms.room_number,
  users.first_name,
  users.last_name,
  users.local_user_id,
  users.email1,
  array_agg(timeblocks.timeblock_name) as periods

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
LEFT JOIN rooms on sections.room_id = rooms.room_id
LEFT JOIN timeblocks on section_timeblock_aff.timeblock_id = timeblocks.timeblock_id

WHERE
  sessions.academic_year = 2019 AND
  section_teacher_aff.primary_teacher is TRUE AND
  section_teacher_aff.end_date > current_date
-- Edit this to choose a site:
--   AND sites.site_name NOT LIKE '%Shasta' AND sites.site_name NOT LIKE '%Tahoma' AND sites.site_name NOT LIKE '%Rainier'
--   AND rooms.room_number LIKE '%MV'
  AND timeblock_name LIKE '%Exped%'
  AND timeblock_name NOT LIKE '%PLT%'

GROUP BY
  sites.site_name,
  sites.site_id,
  courses.school_course_id,
  sections.local_section_id,
  courses.short_name,
  courses.school_course_id,
  rooms.room_number,
  users.first_name,
  users.last_name,
  users.local_user_id,
  users.email1;