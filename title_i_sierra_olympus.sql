/***********************************************************************************************************************
This query produces a roster of currently enrolled students at Sierra and Olympus and indicates whether they are Title I
eligible. Title I eligibility is based on meeting any of the following criteria:
 - Scoring below 50th percentile on MAP Reading or Math in the current school year
 - Not meeting standard on the previous year's SBAC administration in ELA or Math
 - Getting a C+ or below in English or Math in the previous school year
 
To update this query for a new school year, update the following:
 - session ids in the student set table
 - NWEA tables
 - SBAC tables
 - term ids in the grades tables
 **********************************************************************************************************************/

SELECT
  student_set.site_name
  , student_set.local_student_id
  , last_name
  , first_name
  , student_set.grade_level
  , map_reading.map_percentile AS min_map_reading_percentile
  , map_reading.map_term AS min_map_reading_term
  , map_math.map_percentile AS min_map_math_percentile
  , map_math.map_term AS min_map_math_term
  , sbac_ela_met_standard
  , sbac_math_met_standard
  , ela_grade
  , math_grade
  , CASE WHEN map_reading.map_percentile < 50 THEN TRUE
         WHEN map_math.map_percentile < 50 THEN TRUE
         WHEN sbac_ela_met_standard = 'NO' THEN TRUE
         WHEN sbac_math_met_standard = 'NO' THEN TRUE
         WHEN ela_grade IN ('C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'INCOMPLETE') THEN TRUE
         WHEN math_grade IN ('C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'INCOMPLETE') THEN TRUE
         ELSE FALSE
    END AS title_i

FROM
  /* Student set: currently enrolled students at Sierra and Olympus */
  (SELECT
    site_name
    , students.student_id
    , local_student_id
    , last_name
    , first_name
    , grade_level_id - 1 AS grade_level

  FROM public.student_session_aff AS enrollments

  LEFT JOIN public.students ON enrollments.student_id = students.student_id
  LEFT JOIN public.sessions ON enrollments.session_id = sessions.session_id
  LEFT JOIN public.sites ON sessions.site_id = sites.site_id

  WHERE
    enrollments.session_id IN (148, 149)
    AND leave_date > DATE 'today') AS student_set

LEFT JOIN
  /* 2018 MAP reading scores */
  (SELECT
    "nwea_2018_localStudentID" AS local_student_id
    , "nwea_2018_TermName" AS map_term
    , "nwea_2018_TestPercentile" AS map_percentile
    , row_number() OVER(PARTITION BY "nwea_2018_localStudentID" ORDER BY "nwea_2018_TestPercentile") AS row_num

  FROM national_assessments.nwea_2018
  WHERE "nwea_2018_Discipline" = 'Reading') AS map_reading

  ON map_reading.local_student_id = student_set.local_student_id

LEFT JOIN
  /* 2018 MAP math scores */
  (SELECT
    "nwea_2018_localStudentID" AS local_student_id
    , "nwea_2018_TermName" AS map_term
    , "nwea_2018_TestPercentile" AS map_percentile
    , "nwea_2018_Discipline" AS map_discipline
    , row_number() OVER(PARTITION BY "nwea_2018_localStudentID" ORDER BY "nwea_2018_TestPercentile") AS row_num

  FROM national_assessments.nwea_2018
  WHERE "nwea_2018_Discipline" = 'Mathematics'
   ) AS map_math

  ON map_math.local_student_id = student_set.local_student_id

LEFT JOIN
  /* 2017 ELA SBAC scores */
    (SELECT
      student_id,
      "sba_2017_ela_metStandard" AS sbac_ela_met_standard

    FROM state_data_wa.sba_2017_ela

    ) AS sbac_ela

    ON sbac_ela.student_id = student_set.student_id

LEFT JOIN
  /* 2017 math SBAC scores */
    (SELECT
      student_id,
      "sba_2017_math_metStandard" AS sbac_math_met_standard

    FROM state_data_wa.sba_2017_math
    ) AS sbac_math

    ON sbac_math.student_id = student_set.student_id

LEFT JOIN
  /* SY17 math grades */
  (SELECT
    student_grades.student_id,
    courses.school_course_id AS math_course,
    CASE WHEN grades.is_plus IS TRUE THEN CONCAT(grades.grade_description || '+')
         WHEN grades.is_minus IS TRUE THEN CONCAT(grades.grade_description || '-')
         ELSE grades.grade_description
    END AS math_grade

  FROM student_grades
    LEFT JOIN section_grading_period_aff ON section_grading_period_aff.sgpa_id = student_grades.sgpa_id
    LEFT JOIN courses ON courses.course_id = section_grading_period_aff.course_id
    LEFT JOIN grades ON grades.grade_id = student_grades.grade_id
    LEFT JOIN grading_periods ON grading_periods.grading_period_id = section_grading_period_aff.grading_period_id
    LEFT JOIN terms ON terms.term_id = grading_periods.term_id
    LEFT JOIN sessions ON sessions.session_id = terms.session_id

  WHERE
    SUBSTRING(courses.school_course_id,1,1) = 'C' AND
    sessions.academic_year = 2017
  ) math_grades

  ON math_grades.student_id = student_set.student_id

LEFT JOIN
  /* SY17 ELA grades */
  (SELECT
    student_grades.student_id,
    courses.school_course_id AS ela_course,
    CASE WHEN grades.is_plus IS TRUE THEN CONCAT(grades.grade_description || '+')
         WHEN grades.is_minus IS TRUE THEN CONCAT(grades.grade_description || '-')
         ELSE grades.grade_description
    END AS ela_grade

  FROM student_grades
    LEFT JOIN section_grading_period_aff ON section_grading_period_aff.sgpa_id = student_grades.sgpa_id
    LEFT JOIN courses ON courses.course_id = section_grading_period_aff.course_id
    LEFT JOIN grades ON grades.grade_id = student_grades.grade_id
    LEFT JOIN grading_periods ON grading_periods.grading_period_id = section_grading_period_aff.grading_period_id
    LEFT JOIN terms ON terms.term_id = grading_periods.term_id
    LEFT JOIN sessions ON sessions.session_id = terms.session_id

  WHERE
    SUBSTRING(courses.school_course_id,1,1) = 'B' AND
    sessions.academic_year = 2017
  ) ela_grades

  ON ela_grades.student_id = student_set.student_id

WHERE
  -- Filter for lowest math and reading MAP scores
  (map_reading.row_num = 1 OR map_reading.row_num IS NULL)
  AND (map_math.row_num = 1 OR map_math.row_num IS NULL)

ORDER BY site_name, last_name, first_name
