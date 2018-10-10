WITH student_set AS (
 SELECT
   enrollments.student_id
 , enrollments.grade_level_id - 1 AS grade_level
 , sessions.academic_year
 FROM
   -- for selecting school year student set
   student_session_aff AS enrollments
   LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
   LEFT JOIN terms ON sessions.session_id = terms.session_id

 WHERE
   -- student set
   sessions.academic_year = 2019
   AND term_name = 'Year'
   AND sessions.site_id IN(1,2,3,4,5,6,7,8,11,12,13)
)
SELECT
 students.local_student_id as student_id
 , daily_records_ada.date
 , student_set.academic_year
 , attendance_flag_id AS attendance_code
 , attendance_flags.is_present AS attendance_status
 , NOW()::DATE AS as_of
 -- QA columns
--  , student_set.grade_level
--  , sites.site_name

FROM
 student_set
 -- daily_records_ada is the best table to work that we've found
 -- for CA attendance - only get students for whom we have attendance
 INNER JOIN attendance.daily_records_ada USING(student_id)
 -- get the binary for present or not
 LEFT JOIN attendance_flags USING(attendance_flag_id)
 -- get site for QA (site for which attendance was recorded,
 -- not for which they are currently rostered)
 LEFT JOIN sites ON attendance.daily_records_ada.site_id = sites.site_id
 -- needed to get local student id
 LEFT JOIN students USING(student_id)

WHERE
 -- first day of school - only get attendance records for this year
 daily_records_ada.date >= '2018-08-15'

ORDER BY daily_records_ada.date, grade_level, student_id;