-- Queries to get binary present (0 = absent, 1 = present) for all students
-- Can change dates and years accordingly
-- Queries are different for CA and WA due to different attendance flag IDs for each


-- FOR CA
SELECT
  trunc(date_part('day', ada.date :: TIMESTAMP - '2016-08-14' :: TIMESTAMP) / 7) + 1 AS Week_Number,
  ada.date,
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  ssa.grade_level_id - 1                                                             AS grade,
  CASE WHEN
    ada.attendance_flag_id NOT IN (1, 5, 6, 11, 12, 13, 15, 20, 21, 22)
    THEN 0
  ELSE 1
  END
                                                                                     AS present

FROM attendance.daily_records_ada AS ada
  LEFT JOIN sites site ON site.site_id = ada.site_id
  LEFT JOIN students stu ON stu.student_id = ada.student_id
  LEFT JOIN student_session_aff_view ssa ON ssa.student_id = stu.student_id
  LEFT JOIN sessions sess ON sess.session_id = ssa.session_id
WHERE
  date > '2016-08-14'
  AND date <= current_date
  AND sess.academic_year = 2017
GROUP BY
  Week_Number,
  ada.date,
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  grade,
  present
ORDER BY
  site.site_name,
  Week_Number,
  date
  

-- FOR WA
SELECT
  trunc(date_part('day', ada.date :: TIMESTAMP - '2016-08-14' :: TIMESTAMP) / 7) + 1 AS Week_Number,
  ada.date,
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  ssa.grade_level_id - 1                                                             AS grade,
  CASE WHEN
    ada.attendance_flag_id NOT IN (4, 5, 6, 7, 8, 9, 10, 11)
    THEN 0
  ELSE 1
  END
                                                                                     AS present

FROM attendance.daily_records_ada AS ada
  LEFT JOIN sites site ON site.site_id = ada.site_id
  LEFT JOIN students stu ON stu.student_id = ada.student_id
  LEFT JOIN student_session_aff_view ssa ON ssa.student_id = stu.student_id
  LEFT JOIN sessions sess ON sess.session_id = ssa.session_id
WHERE
  date > '2016-08-14'
  AND date < current_date
  AND sess.academic_year = 2017
GROUP BY
  Week_Number,
  ada.date,
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  grade,
  present
ORDER BY
  site.site_name,
  Week_Number,
  date
