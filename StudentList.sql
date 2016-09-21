/*

Summary
• Pulls a list of students that are currently enrolled in at least one class

Level of Detail
• student

*/

SELECT DISTINCT
    TRIM(sites.site_name) AS "Site"
  , grade_levels.short_name::INTEGER AS "Grade Level"
  , students.local_student_id AS "Student ID"
  , students.student_id AS "Illuminate Student ID"
  , TRIM(students.last_name) AS "Student Last Name"
  , TRIM(students.first_name) AS "Student First Name"
  , TRIM(students.middle_name) AS "Student Middle Name"
  , LOWER(students.email) AS "Student Email"
  , users.last_name AS "Mentor Last Name"
  , users.first_name AS "Mentor First Name"
  , LOWER(users.email1) AS "Mentor Email"


FROM
  matviews.ss_cube AS ss
  INNER JOIN sites
    USING (site_id)
  INNER JOIN grade_levels
    USING (grade_level_id)
  INNER JOIN students
    USING (student_id)
  LEFT OUTER JOIN student_counselor_aff AS counselors
    ON counselors.student_id = ss.student_id
    AND counselors.start_date <= CURRENT_DATE
    AND (counselors.end_date IS NULL OR counselors.end_date > CURRENT_DATE)
  LEFT OUTER JOIN users
    ON counselors.user_id = users.user_id



WHERE
      ss.leave_date > CURRENT_DATE
  AND sites.site_name <> 'SPS Tour'


ORDER BY
    "Site"
  , "Grade Level"
  , "Student Last Name"
  , "Student First Name"
