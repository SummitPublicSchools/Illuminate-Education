WITH graduates AS
(
	SELECT 
			sch.site_name
			, ssa.student_id
			, stu.local_student_id
			, stu.last_name
			, stu.first_name
			, gl.short_name
			, ssa.entry_date
			, ssa.leave_date
			, cec.code_translation
		FROM student_session_aff ssa
		
		LEFT JOIN students stu
			ON ssa.student_id = stu.student_id
			
		LEFT JOIN grade_levels gl
			ON ssa.grade_level_id = gl.grade_level_id
			
		LEFT JOIN sessions s
			ON ssa.session_id = s.session_id
			
		LEFT JOIN sites sch
			ON s.site_id = sch.site_id
			
		LEFT JOIN codes.exit_codes cec
			ON ssa.exit_code_id = cec.code_id
						
		WHERE s.academic_year = 2017
			--AND sch.site_name LIKE '%Tahoma%'
			AND cec.code_translation = 'Completer Exit'
)
,

ap_union AS
(
	SELECT * FROM national_assessments.aptest_2017
	
	UNION 
	
	SELECT * FROM national_assessments.aptest_2016
	
	UNION 
	
	SELECT * FROM national_assessments.aptest_2015
	
	UNION 
	
	SELECT * FROM national_assessments.aptest_2014
	
	UNION 
	
	SELECT * FROM national_assessments.aptest_2013
)
,

ap_cleaned AS
(
	SELECT DISTINCT
			student_id
			, TRIM("ap_2017_adminYear") AS admin_year
			--, TRIM("ap_2017_examCode") AS exam_code
			, TRIM("ap_2017_examCodeText") AS exam_name
			, "ap_2017_examGrade" AS exam_grade
		FROM ap_union	
)
,

ap_distinct AS
(
	SELECT DISTINCT * FROM ap_cleaned	
)
,

ap_pass AS
(
	SELECT	
			student_id
			, SUM(CASE WHEN exam_grade >= 3 THEN 1 ELSE 0 END) AS pass_count
		FROM ap_distinct
		
		GROUP BY student_id
)

SELECT
		site_name
		--, local_student_id
		--, last_name
		--, first_name
		--, pass_count
		, SUM(CASE WHEN pass_count >= 1 THEN 1 ELSE 0 END) AS ap_passers
		, COUNT(local_student_id) AS graduates
		, SUM(CASE WHEN pass_count >= 1 THEN 1 ELSE 0 END)::float
			/ COUNT(local_student_id) AS ap_passers_pct 
	FROM graduates g
	
	LEFT JOIN ap_pass ap
		ON g.student_id = ap.student_id
		
	GROUP BY site_name


	




