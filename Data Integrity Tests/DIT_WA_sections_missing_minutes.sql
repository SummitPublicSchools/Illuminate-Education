-- This pulls all currently active WA sections that have either 0 or NULL "minutes per week."
-- This data point is required by the State of WA for reporting. Anything appearing here should be fixed.

SELECT
  sites.site_name,
  sections.section_id,
  courses.short_name,
  timeblocks.timeblock_name as period,
  sessions.academic_year,
  users.last_name AS teacher,
  CASE WHEN (sections.minutes_per_week IS NULL or sections.minutes_per_week = 0)
    THEN TRUE ELSE FALSE END AS no_minutes

FROM sections

LEFT JOIN section_course_aff on section_course_aff.section_id = sections.section_id
LEFT JOIN courses on courses.course_id = section_course_aff.course_id
LEFT JOIN section_term_aff on section_term_aff.section_id = sections.section_id
LEFT JOIN terms on terms.term_id = section_term_aff.term_id
LEFT JOIN sessions on sessions.session_id = terms.session_id
LEFT JOIN section_teacher_aff on section_teacher_aff.section_id = sections.section_id
LEFT JOIN users on users.user_id = section_teacher_aff.user_id
LEFT JOIN sites on sites.site_id = sessions.site_id
LEFT JOIN section_timeblock_aff on section_timeblock_aff.section_id = sections.section_id
LEFT JOIN timeblocks on timeblocks.timeblock_id = section_timeblock_aff.timeblock_id
LEFT JOIN section_teacher_aff_dates on section_teacher_aff_dates.section_id = sections.section_id

WHERE
  section_teacher_aff_dates.end_date > now()
  AND (minutes_per_week = 0
    OR minutes_per_week IS NULL)
  AND sites.site_id <> 9999999
  AND timeblocks.timeblock_name <> 'SPED Caseload'
;
