/*************************************************************************
* identify_transfer_students
*
* Original Author: Jonathon Stewart
* Last Updated: 2018-02-16
*
* Description:
*  Identifies students that have transferred into Summit. This primarily
*  will be used by OMs to ensure that transfer students have all necessary
*  grades.
* 
*  Returns a single row per student with a Y/N flag indicating wether the
*  student is a transfer student.
*
* Ideas for Extension:
*  There is a manual fix to account for Atlas' staggered grade level start.
*  It might be possible to handle this in a more programatic manner. 
***************************************************************************/

WITH enr_current AS (
SELECT
  local_student_id
  , stu.last_name
  , stu.first_name
  , sites.site_name AS current_school
  , sas.grade_level_id - 1 AS current_grade_level
FROM public.student_session_aff AS sas

LEFT JOIN public.students stu ON sas.student_id = stu.student_id
LEFT JOIN public.sessions AS ses ON sas.session_id = ses.session_id
LEFT JOIN public.terms AS terms ON sas.session_id = terms.session_id
LEFT JOIN public.sites AS sites ON ses.site_id = sites.site_id 

WHERE 
--Exclude SPS Tour site
sites.site_id < 9999999

--Return only currently enrolled students
  AND DATE 'today' BETWEEN sas.entry_date AND sas.leave_date
), enr_history AS (
SELECT
  sites.site_name
  , sites.start_grade_level_id - 1 AS site_start_grade_level
  , terms.start_date AS site_start_date
  , stu.local_student_id
  , grade_level_id - 1 AS grade_level
  , ssa.entry_date
  , ssa.leave_date
  
  --Sort enrollment records in ascending order and label earliest record as 1
  , row_number() OVER(PARTITION BY ssa.student_id ORDER BY ssa.entry_date) AS enr_record_num
 FROM public.student_session_aff ssa
 
 LEFT JOIN public.students AS stu ON ssa.student_id = stu.student_id
 LEFT JOIN public.sessions AS ses ON ssa.session_id = ses.session_id
 LEFT JOIN public.terms AS terms ON ssa.session_id = terms.session_id
 LEFT JOIN public.sites AS sites ON ses.site_id = sites.site_id
 
 WHERE
 --Exclude SPS Tour
 sites.site_id < 9999999
  
  AND terms.term_name = 'Year'
), transfer_flags AS (
SELECT
  local_student_id
  , CASE
      --Atlas: flag any student that enrolled >= 100 calendar days after school start
      --regardless of grade level 
      WHEN site_name = 'Summit Public School: Atlas'
        AND entry_date - site_start_date >= 100 THEN 'Y'
      
      --Olympus/Sierra: flag students with earliest enrollment in Gr 10, 11, or 12
      WHEN grade_level > site_start_grade_level THEN 'Y'
      
      --Olympus/Sierra: flag Gr9 students enrolled >= 100 calendar days after school start
      WHEN grade_level = site_start_grade_level
        AND entry_date - site_start_date >= 100 THEN 'Y'
      ELSE 'N'
      END AS is_transfer
 FROM enr_history
 
WHERE
 --Return earliest enrollment record for each student
enr_record_num = 1
)

SELECT
  enr_current.local_student_id
  , enr_current.current_school
  , enr_current.current_grade_level
  , transfer_flags.is_transfer
FROM enr_current
  
LEFT JOIN transfer_flags ON enr_current.local_student_id = transfer_flags.local_student_id