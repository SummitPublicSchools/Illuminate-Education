WITH e AS
(
	SELECT
			s.academic_year
			, sch.site_name
			, stu.local_student_id
			, gl.short_name as grade_level
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
			
		WHERE s.academic_year = 2018
			AND gl.short_name IN ('6', '7', '8', '9','10')
)
,

f AS
(
	SELECT
		"nwea_2018_localStudentID" AS local_student_id
		, "nwea_2018_SchoolName" AS school
		, "nwea_2018_Discipline" AS subject
		, "nwea_2018_TestRITScore" AS test_score
		, "nwea_2018_TestPercentile" AS test_percentile
		, "nwea_2018_TypicalFallToWinterGrowth" AS typical_fall_to_winter_growth
	FROM national_assessments.nwea_2018
	
	WHERE "nwea_2018_TermName" = 'Fall 2017-2018'
		AND "nwea_2018_GrowthMeasureYN" = 'TRUE'
)
, 

w AS
(
	SELECT
			"nwea_2018_localStudentID" AS local_student_id
			, "nwea_2018_SchoolName" AS school
			, "nwea_2018_Discipline" AS subject
			, "nwea_2018_TestRITScore" AS test_score
			, "nwea_2018_TestPercentile" AS test_percentile
			, "nwea_2018_TypicalFallToWinterGrowth" AS typical_fall_to_winter_growth
		FROM national_assessments.nwea_2018
		
		WHERE "nwea_2018_TermName" = 'Winter 2017-2018'
			AND "nwea_2018_GrowthMeasureYN" = 'TRUE'
)
,

g AS
(
	SELECT 
			e.site_name
			, e.local_student_id
			, e.grade_level
			, f.subject
			, f.test_score AS test_score_fall
			, f.test_percentile AS test_percentile_fall
			, f.typical_fall_to_winter_growth AS growth_typical
			, w.test_score AS test_score_winter
			, w.test_percentile AS test_percentile_winter
			, w.test_score - f.test_score AS growth_actual
			, CASE
				WHEN w.test_score - f.test_score >= f.typical_fall_to_winter_growth THEN 'Y'
			ELSE 'N'
			END AS growth_met_typical
	FROM e
	
	INNER JOIN f
		ON e.local_student_id = f.local_student_id
			AND e.site_name = f.school
	
	INNER JOIN w 
		ON f.local_student_id = w.local_student_id
			AND f.subject = w.subject
			AND f.school = w.school
				
	ORDER BY e.grade_level, f.subject, f.local_student_id
)

SELECT
		g.site_name
		, g.subject
		--, g.grade_level
		, SUM(CASE WHEN growth_met_typical = 'Y' THEN 1 ELSE 0 END) AS cnt_met_typical
		, COUNT(local_student_id) AS cnt_students
		, SUM(CASE WHEN growth_met_typical = 'Y' THEN 1.0 ELSE 0.0 END)
			/ COUNT(local_student_id) AS pct_met_typical
	FROM g
	
	--WHERE test_percentile_fall <= 25
	
	GROUP BY g.site_name, g.subject
	
	ORDER BY g.site_name, g.subject