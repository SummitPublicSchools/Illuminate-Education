
-- This pulls a list of all sections in the current academic year that do not have a local section id. 
-- This local section id is needed for Core Data Imports.
-- You can ask the Illuminate Help Desk to copy the section_id over to the local_section_id.
SELECT
  sites.site_name,
  sections.section_id,
  sections.local_section_id,
  courses.school_course_id,
  courses.short_name

FROM sections

LEFT JOIN section_course_aff on sections.section_id = section_course_aff.section_id
LEFT JOIN courses on courses.course_id = section_course_aff.course_id
LEFT JOIN section_term_aff on sections.section_id = section_term_aff.section_id
LEFT JOIN terms on terms.term_id = section_term_aff.term_id
LEFT JOIN sessions on sessions.session_id = terms.session_id
LEFT JOIN sites on sites.site_id = sessions.site_id

WHERE sessions.academic_year = 2019 AND
  sites.site_id < 100 AND
  local_section_id IS NULL AND
  school_course_id IS NOT NULL

ORDER BY sites.site_name;
