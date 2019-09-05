/* Returns enrollment by date and grade for each school based on the school year specified
Comment out the grade portion in the SELECT statement to get enrollment for the whole school, rather than by grade
 */

SELECT
  dates_school_in_session.day :: DATE,
  enrollments_SY17.site_name,
  enrollments_SY17.grade, -- < can comment out to get enrollment for whole school instead of by grade
  COUNT(enrollments_SY17.student_id) AS enrollment_count

FROM
  (SELECT
     enrollments.student_id,
     enrollments.grade_level_id - 1 AS grade,
     enrollments.entry_date,
     enrollments.leave_date,
     sites.site_id,
     sites.site_name
   FROM public.student_session_aff AS enrollments
     LEFT JOIN public.sessions USING (session_id)
     LEFT JOIN codes.session_types session_type_codes ON
                                                        sessions.session_type_id = session_type_codes.code_id
     LEFT JOIN public.sites AS sites ON public.sessions.site_id = sites.site_id
   
   WHERE

     /* !!! Enter the academic year you're looking at here !!! */
     sessions.academic_year = 2016

     AND sites.site_name != 'SPS Tour'
     AND session_type_codes.code_translation != 'Summer'
  ) enrollments_SY17
  
  CROSS JOIN
  (SELECT
      public.calendar_days.date :: DATE AS day,
      sites.site_id
    FROM public.calendar_days
      LEFT JOIN public.day_types USING (day_type_id)
      LEFT JOIN public.sites USING (site_id)
    WHERE public.day_types.in_session = 1
  ) dates_school_in_session

WHERE
  dates_school_in_session.day :: DATE >= enrollments_SY17.entry_date AND
  dates_school_in_session.day :: DATE <= enrollments_SY17.leave_date AND
  enrollments_SY17.site_id = dates_school_in_session.site_id

GROUP BY dates_school_in_session.day :: DATE, enrollments_SY17.site_name, enrollments_SY17.grade
ORDER BY enrollments_SY17.site_name, enrollments_SY17.grade, dates_school_in_session.day :: DATE
