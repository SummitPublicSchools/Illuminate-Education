WITH enr17 AS
(
	SELECT
			sta.student_id
			, sta.term_id
			, grade_level_id
			, MIN(entry_date) AS entry_date
			, MAX(COALESCE(leave_date, t.end_date)) AS leave_date
		FROM matviews.student_term_aff sta
		
		LEFT JOIN students stu
			ON sta.student_id = stu.student_id
			
		LEFT JOIN terms t
			ON sta.term_id = t.term_id
			
		--WHERE local_student_id = '120111'
		
		GROUP BY sta.student_id
					, sta.term_id
					, grade_level_id
)
,

sy17 AS
(
	SELECT
			s.academic_year
			, sch.site_name
			, local_student_id
			, gl.short_name as grade_level
			, entry_date
			, leave_date
			--, cec.code_key
			--, cec.code_translation
			, CASE
				WHEN '10/05/2016' BETWEEN entry_date AND leave_date THEN 'Y'
				ELSE 'N'
				END AS enrolled_cbeds
			, CASE
				WHEN entry_date = t.start_date THEN 'Y'
				ELSE 'N'
				END AS enrolled_first_day
			, CASE
				WHEN leave_date = t.end_date THEN 'Y'
				ELSE 'N'
				END AS enrolled_last_day
		FROM enr17 sta
		
		LEFT JOIN students stu
			on sta.student_id = stu.student_id
			
		LEFT JOIN grade_levels gl
			ON sta.grade_level_id = gl.grade_level_id
			
		LEFT JOIN terms t
			ON sta.term_id = t.term_id
			
		LEFT JOIN sessions s
			ON t.session_id = s.session_id
			
		LEFT JOIN sites sch
			ON s.site_id = sch.site_id
			
		--LEFT JOIN codes.exit_codes cec
		--	ON sta.exit_code_id = cec.code_id
			
		WHERE s.academic_year = 2017
)

SELECT
		academic_year
		--, site_name
		
		, SUM(CASE WHEN enrolled_last_day = 'Y' THEN 1 ELSE 0 END) AS cnt_stayed
		, SUM(CASE WHEN enrolled_last_day = 'N' THEN 1 ELSE 0 END) AS cnt_left
		, COUNT(local_student_id) AS cnt_cbeds
		
		, ROUND(SUM(CASE WHEN enrolled_last_day = 'Y' THEN 1.0000 ELSE 0.0000 END)
			/ COUNT(local_student_id), 3) * 100 AS pct_stayed
		, ROUND(SUM(CASE WHEN enrolled_last_day = 'N' THEN 1.0000 ELSE 0.0000 END)
			/ COUNT(local_student_id), 3) * 100 AS pct_left
	FROM sy17 
	
	WHERE enrolled_cbeds = 'Y'
	
	GROUP BY academic_year
				--, site_name
	
	