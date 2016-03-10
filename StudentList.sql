SELECT
  site_name AS "School",
  short_name AS "Grade Level",
  local_student_id AS "Student ID",
  student_id AS "Illuminate Student ID",
  last_name AS "Student Last Name",
  first_name AS "Student First Name",
  middle_name AS "Student Middle Name",
  email AS "Student Email"


FROM matviews.ss_cube
  INNER JOIN sites USING (site_id)
  INNER JOIN grade_levels USING (grade_level_id)
  INNER JOIN students USING (student_id)


WHERE leave_date >= CURRENT_DATE
  AND site_name <> 'SPS Tour'


GROUP BY
  site_name,
  short_name,
  local_student_id,
  student_id,
  last_name,
  first_name,
  middle_name,
  email

ORDER BY site_name,short_name::INTEGER

;
