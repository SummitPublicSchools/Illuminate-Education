/*

Summary
• Pulls a list of currently enrolled students

Level of Detail
• student

*/

SELECT DISTINCT
  site_name AS "School",
  short_name::INTEGER AS "Grade Level",
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


ORDER BY
  site_name,
  short_name::INTEGER
