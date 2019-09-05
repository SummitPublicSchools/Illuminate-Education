SELECT *
FROM crosstab(
	'SELECT
			local_student_id
			, short_name
			, school_course_id
		FROM (
			SELECT DISTINCT
				local_student_id
				, last_name
				, first_name
				, gender
				, grade_level_id - 1 AS grade_level
				, school_course_id
				, crs.short_name
			FROM student_session_aff ssa
			
			LEFT JOIN students stu
				ON ssa.student_id = stu.student_id
			
			LEFT JOIN sessions s
				ON ssa.session_id = s.session_id
				
			LEFT JOIN sites sch
				ON s.site_id = sch.site_id
				
			LEFT JOIN section_student_aff sec_sa
				ON ssa.student_id = sec_sa.student_id
				
			LEFT JOIN sections sec
				ON sec_sa.section_id = sec.section_id
				
			LEFT JOIN section_course_aff sca
				ON sec.section_id = sca.section_id
				
			LEFT JOIN courses crs
				ON sca.course_id = crs.course_id
				
			LEFT JOIN section_term_aff sta
				ON sec.section_id = sta.section_id
				
			WHERE 1=1
				AND s.academic_year = 2018
				AND sch.site_name LIKE ''%Olympus%''
				AND grade_level_id - 1 = 11
				AND sec_sa.entry_date > ''08/01/2017''
				AND sec_sa.leave_date IS NULL
				AND LEFT(school_course_id, 1) NOT IN (''I'', ''H'', ''S'', ''R'')
	) cr')
AS ct(student_id CHARACTER VARYING
		, course_one CHARACTER VARYING
		, course_two CHARACTER VARYING
		, course_three CHARACTER VARYING
		, course_four CHARACTER VARYING
		, course_five CHARACTER VARYING
		, course_six CHARACTER VARYING
		, course_seven CHARACTER VARYING)