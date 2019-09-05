-----------------------------------------------------------------------------------------
-- Retained or Persisted Students between Two Dates
-- --------------------------------------------------------------------------------------
-- Author: Patrick Yoho
-- Year: Fall SY19
--
-- Gets the percentage of students with persisted enrollment between two dates. It does
-- this regardless of if the student gets held back a grade.
-----------------------------------------------------------------------------------------
WITH
  student_set_start AS (
    SELECT DISTINCT
      student_id
      , CASE WHEN sessions.site_id = 9999997 THEN 7  -- Include K2 NPS with K2
             ELSE sessions.site_id END
      , grade_level_id
    FROM
      public.student_session_aff AS enrollments
      LEFT JOIN public.sessions AS sessions
        ON enrollments.session_id = sessions.session_id
    WHERE
      sessions.academic_year = 2019
      AND DATE '2018-08-15' BETWEEN enrollments.entry_date AND enrollments.leave_date
  )
  , student_set_end AS (
    SELECT DISTINCT
      student_id
      , CASE WHEN sessions.site_id = 9999997 THEN 7  -- Include K2 NPS with K2
             ELSE sessions.site_id END
      , grade_level_id
    FROM
      public.student_session_aff AS enrollments
      LEFT JOIN public.sessions AS sessions
        ON enrollments.session_id = sessions.session_id
    WHERE
      sessions.academic_year = 2019
      AND DATE '2019-03-23' BETWEEN enrollments.entry_date AND enrollments.leave_date
  )
  , number_of_enrolled_and_retained_students AS (
    SELECT
      --enrollments_prev_year.student_id
      sites.site_name
      , grade_levels.short_name                    AS "grade_level"
      , COUNT(student_set_start.student_id)    AS "enrolled_students"
      , COUNT(student_set_end.student_id) AS "retained_or_persisted_students"
    FROM
      student_set_start
      LEFT JOIN student_set_end USING (student_id, site_id)
      LEFT JOIN public.sites AS sites
        ON student_set_start.site_id = sites.site_id
      LEFT JOIN grade_levels on student_set_start.grade_level_id = grade_levels.grade_level_id

    WHERE
      site_name <> 'SPS Tour'

    GROUP BY site_name, grade_level, sort_order

    ORDER BY site_name, grade_levels.sort_order
  )
--SELECT * FROM number_of_enrolled_and_retained_students;
SELECT *,
  retained_or_persisted_students::FLOAT / enrolled_students AS "retention_or_persistence_rate"
FROM number_of_enrolled_and_retained_students;