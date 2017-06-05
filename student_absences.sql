-- Queries to get total absences disaggregated by excused and unexcused over a date range
-- Queries are different for CA and WA due to different attendance flag IDs for each

-- FOR CA - Total Absences (excused and unexcused) YTD
SELECT
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  ssa.grade_level_id - 1                                                             AS grade,
  SUM(CASE WHEN
    ada.attendance_flag_id IN (3, 4)
    THEN 1
        ELSE 0
        END)
                                                                                     AS unexcused_absences,
  SUM(CASE WHEN
    ada.attendance_flag_id IN (8, 7, 9, 10, 23, 2, 14)
    THEN 1
        ELSE 0
        END)                                                                         AS excused_absences

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
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  grade
ORDER BY
  site.site_name



-- FOR WA - Total Absences (excused and unexcused) YTD
SELECT
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  ssa.grade_level_id - 1                                                             AS grade,
  SUM(CASE WHEN
    ada.attendance_flag_id IN (12, 20)
    THEN 1
        ELSE 0
        END)
                                                                                     AS unexcused_absences,
  SUM(CASE WHEN
    ada.attendance_flag_id IN (13, 14, 15, 16, 17, 18, 19)
    THEN 1
        ELSE 0
        END)                                                                         AS excused_absences

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
  site.site_name,
  site.site_id,
  ada.student_id,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  grade
ORDER BY
  site.site_name
