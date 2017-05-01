/*
  Supply a date in the where block and this will return the enrollment
  count on that day. Some very small modification can lead to getting
  the student ids of the people enrolled on that date.
*/

SELECT sites.site_name,
  enrollments.grade_level_id - 1,
  COUNT(enrollments.student_id)

FROM
  -- Start with enrollment records (according to Illuminate, this is supposed
  -- to be the authoritative table for enrollment records)
  public.student_session_aff AS enrollments

  LEFT JOIN public.sessions AS sessions
    ON enrollments.session_id = sessions.session_id
  LEFT JOIN public.sites as sites
    ON sessions.site_id = sites.site_id

WHERE
  enrollments.entry_date <= '2017/04/11' AND
  enrollments.leave_date >= '2017/04/11'

GROUP BY sites.site_name, enrollments.grade_level_id

ORDER BY sites.site_name, enrollments.grade_level_id;
