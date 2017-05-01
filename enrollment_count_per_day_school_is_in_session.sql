/*
  enrollment_count_per_day_school_is_in_session.sql
  This is a particularly clever query that will get an enrollment count for
  every day that any school was in session.

  HOW TO USE:
  You'll want to provide a date range in the enrollments subquery for the
  date range you actually want.

  SUGGESTED MODIFICATIONS:
  - Add in a site and/or a grade to the enrollments subquery and the main
    SELECT statement to get enrollment per site and/or grade.
  - This basic query structure (using the cross join) can be used for any
    query where you want to look at a count over time.
*/

SELECT
    dates_school_in_session.day :: DATE,
    COUNT(enrollments.student_id) AS enrollment_count

  FROM (
      SELECT
         enrollments.student_id,
         enrollments.entry_date,
         enrollments.leave_date
       FROM public.student_session_aff AS enrollments
       WHERE enrollments.entry_date >= '2016-08-16' AND
        enrollments.leave_date <= '2017-07-31'
    ) enrollments
    CROSS JOIN (
      SELECT DISTINCT public.calendar_days.date::DATE AS day
      FROM public.calendar_days
        LEFT JOIN public.day_types USING (day_type_id)
      WHERE public.day_types.in_session = 1
    ) dates_school_in_session


  WHERE
    dates_school_in_session.day :: DATE >= enrollments.entry_date AND
    dates_school_in_session.day :: DATE <= enrollments.leave_date

  GROUP BY dates_school_in_session.day :: DATE
  ORDER BY dates_school_in_session.day :: DATE
