/*

Summary
• Queries historical student enrollment records

Level of Detail
• student > enrollment record

*/


SELECT

    students.local_student_id AS "SPS ID"
  , students.student_id AS "Illuminate Student ID"
  , students.state_student_id AS "State Student ID"
  , TRIM(students.last_name) AS "Student Last Name"
  , TRIM(students.first_name) AS "Student First Name"
  , TRIM(sites.site_name) AS "Site Name"
  , students.school_enter_date AS "School Enter Date"
  , sessions.academic_year AS "Academic Year"
  , enrollments.entry_date AS "Entry Date"
  , enrollments.leave_date AS "Leave Date"
  , grade_levels.short_name::INTEGER AS "Grade Level"
  --, entry_codes.code_key AS "Entry Code"
  , exit_codes.code_key AS "Exit Code"
  , exit_codes.code_translation AS "Exit Description"


FROM
  -- Start with enrollment records (according to Illuminate, this is supposed to be the authoritative table for enrollment records)
  public.student_session_aff AS enrollments

  -- Join enrollment records to students, grade levels, sessions, and sites
  INNER JOIN public.students AS students
    ON enrollments.student_id = students.student_id
  INNER JOIN public.grade_levels AS grade_levels
    ON enrollments.grade_level_id = grade_levels.grade_level_id
  INNER JOIN public.sessions AS sessions
    ON enrollments.session_id = sessions.session_id
  INNER JOIN public.sites AS sites
    ON sessions.site_id = sites.site_id

  -- Join enrollment records and sessions to code tables to decode what the ids represent
  LEFT JOIN codes.exit_codes AS exit_codes
    ON enrollments.exit_code_id = exit_codes.code_id
  LEFT JOIN codes.entry_codes AS entry_codes
    ON enrollments.entry_code_id = entry_codes.code_id
  LEFT JOIN codes.session_types AS session_type_codes
    ON sessions.session_type_id = session_type_codes.code_id


WHERE
  -- Optional: include next line to exclude Summer terms
  session_type_codes.code_translation != 'Summer'


ORDER BY
    students.last_name
  , students.first_name
  , sessions.academic_year
  , enrollments.entry_date
  , sites.site_name
  , grade_levels.short_name
