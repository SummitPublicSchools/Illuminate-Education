SELECT DISTINCT
  sites.site_name AS "Current Site Name",
  students.local_student_id AS "Student ID",
  TRIM(students.last_name) AS "Last Name",
  TRIM(students.first_name) AS "First Name",
  grade_levels.short_name::INTEGER AS "Current Grade Level",
  counselors.user_id AS "Counselor ID"



FROM
  public.student_session_aff AS enrollments

  INNER JOIN public.students AS students
    ON enrollments.student_id = students.student_id
  INNER JOIN public.grade_levels AS grade_levels
    ON enrollments.grade_level_id = grade_levels.grade_level_id
  INNER JOIN public.sessions as sessions
    ON enrollments.session_id = sessions.session_id
  INNER JOIN public.sites AS sites
    ON sessions.site_id = sites.site_id

  LEFT JOIN matviews.ss_current AS ss_current
    ON enrollments.student_id = ss_current.student_id


  LEFT JOIN public.student_counselor_aff AS counselors
    ON students.student_id = counselors.student_id



WHERE
  sessions.academic_year = 2017 AND
  ss_current.student_id IS NOT NULL and
  counselors.user_id IS NULL
