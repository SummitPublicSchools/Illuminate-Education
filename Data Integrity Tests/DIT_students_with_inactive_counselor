SELECT
  sites.site_name,
  stud.local_student_id,
  stud.last_name,
  stud.first_name,
  ss.grade_level_id - 1 AS grade,
  u.last_name              counselor_last,
  u.first_name             counselor_first,
  u.active

FROM matviews.ss_current AS ss

  LEFT JOIN students stud USING (student_id)
  LEFT JOIN sites USING (site_id)
  LEFT JOIN student_counselor_aff sca USING (student_id)
  LEFT JOIN users u USING (user_id)

WHERE
  ss.site_id NOT IN (9999999, 9999998)
  AND
  sca.end_date IS NULL
  AND
  u.active IS FALSE
