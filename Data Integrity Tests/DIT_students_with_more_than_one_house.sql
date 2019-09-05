SELECT
  sites.site_name,
  stud.local_student_id,
  stud.last_name,
  stud.first_name,
  ss.grade_level_id - 1 AS grade,
  h.house_name,
  COUNT(*)

FROM matviews.ss_current AS ss

  LEFT JOIN students stud USING (student_id)
  LEFT JOIN sites USING (site_id)
  LEFT JOIN student_counselor_aff sca USING (student_id)
  LEFT JOIN users u USING (user_id)
  LEFT JOIN student_house_aff sha USING (student_id)
  LEFT JOIN houses h USING (house_id)

WHERE
  ss.site_id NOT IN (9999999, 9999998)


GROUP BY
  site_name, local_student_id, stud.last_name, stud.first_name, grade, house_name
HAVING
  COUNT(*) > 1
