/******************************************************************
* number_of_transfers_in_or_out_per_grade.sql
* author: Patrick Yoho
* This requires some manual manipulation of the query, but can
* get the number of transfers in or out of a school site that
* occurred during the year. Originally developed for this data
* request ticket: 
* https://help.summitps.org/incidents/28256147-fwd-data-on-everest
*******************************************************************/

-- Use this query to check which terms were a part of the specific 
-- school year. We don't want to count Summer of Summit (SoS) terms.
SELECT DISTINCT
  terms.term_name

FROM
  student_session_aff AS enrollments
    LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
    LEFT JOIN terms ON sessions.session_id = terms.session_id

WHERE sessions.academic_year = 2018;


-- This query provides the basic structure for figuring out the number
-- of students who entered after the first day of school or exited
-- before the last day of school per grade. This is proxy for counting
-- the number of entries and exits that occurred during the school 
-- year (number of transfers in and out).
WITH student_set AS (
  SELECT DISTINCT
    enrollments.student_id
    ,grade_level_id - 1 AS grade_level
    ,enrollments.entry_date
    ,enrollments.leave_date
  FROM
    student_session_aff AS enrollments
    LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
    LEFT JOIN terms ON sessions.session_id = terms.session_id

  WHERE
    sessions.site_id = 4

    -- filter out any term enrollments that you don't want
    AND term_name <> 'NPS'

    AND sessions.academic_year = 2018
)
SELECT
  grade_level
  ,COUNT(student_id)

FROM student_set

WHERE
  -- Comment one of these out to get either the number of entries
  -- or exits.
  --entry_date > '2017-08-15'
  leave_date < '2018-06-07'

GROUP BY grade_level
ORDER BY grade_level;
