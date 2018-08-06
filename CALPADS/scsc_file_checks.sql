/* WIP - FOR SCSC File checks*/

SELECT
  sites.site_name,
  students.state_student_id,
  students.local_student_id,
  students.first_name,
  students.last_name,
  departments.department_name,
  courses.school_course_id,
  courses.short_name,
  matviews.student_grades_transcript.academic_year,
  grades.grade,
  matviews.student_grades_transcript.credits_possible AS attempted,
  matviews.student_grades_transcript.credits_received AS received,
  matviews.student_grades_transcript.is_repeat,
  courses.exclude_from_state_reporting,
  COUNT(courses.school_course_id) OVER (PARTITION BY local_student_id) AS courses_reported_per_stu
  --TODO: Find UC/CSU Requirement field in Illuminate DB and add here

FROM student_session_aff enrollments
LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
LEFT JOIN students ON enrollments.student_id = students.student_id
LEFT JOIN sites ON sessions.site_id = sites.site_id
LEFT JOIN matviews.student_grades_transcript ON matviews.student_grades_transcript.student_id = enrollments.student_id
LEFT JOIN courses ON courses.course_id = matviews.student_grades_transcript.course_id
LEFT JOIN departments ON departments.department_id = courses.department_id
LEFT JOIN grades on grades.grade_id = matviews.student_grades_transcript.grade_id

WHERE student_grades_transcript.academic_year = 2018
AND sessions.academic_year = 2018
AND department_name NOT IN ('Transfer', 'Summer','Intersession')