SELECT
all_sy_19_gr.site_name, all_sy_19_gr.school_course_id, all_sy_19_gr.current_grade_level, count(all_sy_19_gr.local_student_id)

FROM


(SELECT
  students.local_student_id || ssa.section_id as lookup
  , sites.site_name
  , matviews.ss_current.site_id
  , students.local_student_id
  , students.last_name
  , students.first_name
  , (matviews.ss_current.grade_level_id - 1) as current_grade_level
  , houses.house_name
  , ssa.section_id
  , sections.local_section_id
  , departments.department_name
  , courses.school_course_id
  , courses.short_name
  , users.local_user_id
  , users.last_name
  , ssa.entry_date
  , ssa.leave_date
  , courses.variable_credits_high

FROM
  matviews.ss_current

LEFT JOIN section_student_aff as ssa on ssa.student_id = matviews.ss_current.student_id
LEFT JOIN students on ssa.student_id = students.student_id
LEFT JOIN sections ON ssa.section_id = sections.section_id
LEFT JOIN courses ON ssa.course_id = courses.course_id
LEFT JOIN sites on matviews.ss_current.site_id = sites.site_id
LEFT JOIN departments on courses.department_id = departments.department_id
LEFT JOIN section_teacher_aff as sta on sections.section_id = sta.section_id
LEFT JOIN users on sta.user_id = users.user_id
LEFT JOIN student_house_aff sha on students.student_id = sha.student_id
FULL JOIN houses on sha.house_id = houses.house_id
LEFT JOIN sessions on sessions.site_id = sites.site_id

WHERE
  matviews.ss_current.site_id < 100 AND
  courses.transcript_inclusion IS NOT FALSE AND
  courses.is_active IS TRUE AND
  courses.variable_credits_high  >= 0.5 AND
  (ssa.leave_date > now() OR ssa.leave_date IS NULL) AND
  ssa.entry_date > '2018-08-01' AND
  ssa.entry_date < now() AND
  (sta.end_date > '2018-12-01' OR sta.end_date IS NULL) AND
  sta.primary_teacher IS TRUE AND
    sha.session_id IN (SELECT sessions.session_id FROM sessions WHERE sessions.academic_year = 2019)

--   AND local_student_id = '60589'
--   AND house_name = 'No House'
-- AND school_course_id = 'I289'

GROUP BY
  sites.site_name
  , matviews.ss_current.site_id
  , students.local_student_id
  , students.last_name
  , students.first_name
  , matviews.ss_current.grade_level_id
  , houses.house_name
  , ssa.section_id
  , sections.local_section_id
  , departments.department_name
  , courses.school_course_id
  , courses.short_name
  , users.local_user_id
  , users.last_name
  , ssa.entry_date
  , ssa.leave_date
  , courses.variable_credits_high

ORDER BY
  site_name,
  current_grade_level,
  students.last_name,
  first_name,
  school_course_id) as all_sy_19_gr

WHERE
    all_sy_19_gr.school_course_id NOT LIKE '%M'
    AND all_sy_19_gr.school_course_id NOT LIKE 'I%'

GROUP BY
         all_sy_19_gr.site_name, all_sy_19_gr.school_course_id, all_sy_19_gr.current_grade_level

ORDER BY
         site_name, current_grade_level, school_course_id