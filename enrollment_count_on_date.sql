/*************************************************************************
* enrollment_count_on_date
**************************************************************************
* Original Author: Patrick Yoho
* Last Updated: 2018-02-11
*
* Description:
*  Supply a date in the WHERE block and this query will return the 
*  enrollment count on that day. 
*
* Ideas for Extension
*  This query is a useful starting point for getting information about
*  students who had an enrollment on a specific date. You could, for
*  example, get the local_student_ids for all students enrolled on a
*  particular date.  - 
*/

SELECT
  sites.site_name,
  enrollments.grade_level_id - 1 AS grade,
  COUNT(enrollments.student_id) AS number_of_enrolled_students,

FROM
  -- Start with enrollment records (according to Illuminate, this is supposed
  -- to be the authoritative table for enrollment records)
  public.student_session_aff AS enrollments

  LEFT JOIN public.sessions AS sessions
    ON enrollments.session_id = sessions.session_id
  LEFT JOIN public.sites AS sites
    ON sessions.site_id = sites.site_id

WHERE
  enrollments.entry_date <= '2017/04/11' AND
  enrollments.leave_date >= '2017/04/11'

GROUP BY sites.site_name, enrollments.grade_level_id

ORDER BY sites.site_name, enrollments.grade_level_id;
