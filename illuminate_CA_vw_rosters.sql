/***************************************************************************************
Description:
Returns a single row per student with local ID, first name, last name, grade level, house
, entry date, exit date.  Results can be easily filtered for any date, school, or house.
***************************************************************************************/

WITH current_enrollment AS (
		SELECT
			sch.site_name
			, stu.local_student_id
			, stu.last_name
			, stu.first_name
			, gl.short_name AS grade_level
			, enr.entry_date
			--If leave date is null, insert the end of term date
			, COALESCE(enr.leave_date, ter.end_date) AS leave_date
			, hou.house_name
		FROM matviews.student_term_aff AS enr
		
		LEFT JOIN public.grade_levels AS gl ON enr.grade_level_id = gl.grade_level_id
		LEFT JOIN public.terms AS ter ON enr.term_id = ter.term_id
		LEFT JOIN public.sessions AS ses ON ter.session_id	= ses.session_id
		LEFT JOIN public.sites AS sch ON ses.site_id = sch.site_id
		LEFT JOIN public.students AS stu ON enr.student_id = stu.student_id
		
		--Join house info on student_id and session_id
		LEFT JOIN public.student_house_aff AS sha ON enr.student_id = sha.student_id
			AND ses.session_id = sha.session_id
		LEFT JOIN public.houses AS hou ON sha.house_id = hou.house_id
			AND ses.session_id = hou.session_id
	)
	
	SELECT
		site_name
		, local_student_id
		, last_name
		, first_name
		, grade_level
		, house_name
		, entry_date
		, leave_date
		, CURRENT_TIMESTAMP AS time_stamp
	FROM current_enrollment
	
	WHERE 
		site_name <> 'SPS Tour' 
