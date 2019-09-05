WITH sy17 AS
(
	SELECT
			s.academic_year
			, sch.site_name
			, local_student_id
			, gl.short_name as grade_level
			, entry_date
			, COALESCE(leave_date, t.end_date) AS leave_date
			, cec.code_key
			, cec.code_translation
			, CASE
				WHEN '10/05/2016' BETWEEN entry_date AND COALESCE(leave_date, t.end_date) THEN 'Y'
				ELSE 'N'
				END AS enrolled_cbeds
			, CASE
				WHEN entry_date = t.start_date THEN 'Y'
				ELSE 'N'
				END AS enrolled_first_day
			, CASE
				WHEN leave_date IS NULL THEN 'Y'
				ELSE 'N'
				END AS enrolled_last_day
		FROM matviews.student_term_aff sta
		
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
			
		LEFT JOIN codes.exit_codes cec
			ON sta.exit_code_id = cec.code_id
			
		WHERE s.academic_year = 2017
)
,

sy18 AS (
	SELECT
			s.academic_year
			, sch.site_name
			, local_student_id
			, gl.short_name as grade_level
			, entry_date
			, COALESCE(leave_date, t.end_date) as leave_date
			, cec.code_key
			, cec.code_translation
			, CASE
				WHEN '10/04/2017' BETWEEN entry_date AND COALESCE(leave_date, t.end_date) THEN 'Y'
				ELSE 'N'
				END AS enrolled_cbeds
			, CASE
				WHEN entry_date = t.start_date THEN 'Y'
				ELSE 'N'
				END AS enrolled_first_day
			, CASE
				WHEN leave_date IS NULL THEN 'Y'
				ELSE 'N'
				END AS enrolled_last_day
		FROM matviews.student_term_aff sta
		
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
			
		LEFT JOIN codes.exit_codes cec
			ON sta.exit_code_id = cec.code_id
			
		WHERE s.academic_year = 2018 
)
, 

attrition AS
(
	SELECT
			sy17.academic_year
			, sy17.site_name
			, sy17.local_student_id
			, sy17.grade_level
			, sy17.entry_date AS sy17_entry_date
			, sy17.leave_date AS sy17_leave_date
			, sy17.enrolled_cbeds AS sy17_enrolled_cbeds
			, sy18.entry_date AS sy18_entry_date
			, sy18.leave_date AS sy18_leave_date
			, COALESCE(sy18.enrolled_cbeds, 'N') AS sy18_returned
		FROM sy17
		
		LEFT JOIN sy18
			ON sy17.local_student_id = sy18.local_student_id
				AND sy17.site_name = sy18.site_name
		
		WHERE sy17.grade_level <> '12' --Seniors not expected to return
			AND sy17.enrolled_cbeds = 'Y'
)

SELECT
		academic_year
		, site_name
		
		, SUM(CASE WHEN sy18_returned = 'Y' THEN 1 ELSE 0 END) AS cnt_returned
		, SUM(CASE WHEN sy18_returned = 'N' THEN 1 ELSE 0 END) AS cnt_left
		, COUNT(local_student_id) AS cnt_sy17_cbeds
		
		, ROUND(SUM(CASE WHEN sy18_returned = 'Y' THEN 1.0000 ELSE 0.0000 END)
			/ COUNT(local_student_id), 3) * 100 AS pct_stayed
		, ROUND(SUM(CASE WHEN sy18_returned = 'N' THEN 1.0000 ELSE 0.0000 END)
			/ COUNT(local_student_id), 3) * 100 AS pct_left
	FROM attrition 
	
	--GROUP BY academic_year
	--			, site_name
				
	GROUP BY GROUPING SETS (academic_year, (academic_year, site_name))
	
	