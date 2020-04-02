/***********************************************************************************************************************
This query produces a roster of currently enrolled students at Atlas, Olympus, and Sierra and indicates whether they are LAP
eligible. LAP eligibility is based on meeting TWO of the criteria in MAP, Subject Letter Grade, or SBAC:

-------

LAP MATH:

1) Bottom 20th percentile  (<= 20)on MAP Math in most recent test administration for that student
(considering current and previous school year; if student took test more than once in most recent administration, use highest score)

2) <= C+ in Math in the previous year

3) NOT meeting grade level standard on previous year's SBAC Math administration

-------

LAP ELA:

1) Bottom 20th percentile (<= 20) on MAP Reading in most recent test administration for that student
(considering current and previous school year; if student took test more than once in most recent administration, use highest score)

2) <= C+ in English in the previous year

3) NOT meeting grade level standard on previous year's SBAC ELA administration

-------

To update this query for a new school year, update the following:
 - first day of school
 - Fall snapshot date (must be after Fall MAP Testing window closes)
 - NWEA tables
 - SBAC tables
 - academic year in the grades tables
 **********************************************************************************************************************/

SELECT
  student_set.site_name
  , student_set.local_student_id
  , last_name
  , first_name
  , student_set.grade_level
  , map_math.map_percentile AS min_map_math_percentile
  , map_math.map_term AS min_map_math_term
  , math_grade
  , sbac_math_met_standard
  , CASE WHEN (
                (map_math.map_percentile <= 20 AND math_grade IN ('C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'INCOMPLETE'))
                OR (map_math.map_percentile <= 20 AND sbac_math_met_standard = 'NO')
                OR (sbac_math_met_standard = 'NO' AND math_grade IN ('C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'INCOMPLETE'))
              ) THEN TRUE
         ELSE FALSE
    END AS lap_math
  , map_reading.map_percentile AS min_map_reading_percentile
  , map_reading.map_term AS min_map_reading_term
  , ela_grade
  , sbac_ela_met_standard
  , CASE WHEN (
                (map_reading.map_percentile <= 20 AND ela_grade IN ('C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'INCOMPLETE'))
                OR (map_reading.map_percentile <= 20 AND sbac_ela_met_standard = 'NO')
                OR (sbac_ela_met_standard = 'NO' AND ela_grade IN ('C+', 'C', 'C-', 'D+', 'D', 'D-', 'F', 'INCOMPLETE'))
              ) THEN TRUE
         ELSE FALSE
    END AS lap_ela


FROM
  /* Student set: students enrolled at Atlas, Olympus, and Sierra on 11/01 */
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
    enrollments.entry_date >= DATE '2018-08-21' --their enrollment was after the first day of school for this SY
    AND enrollments.entry_date <= DATE '2018-11-01' -- enrollment was on or before the snapshot date
    AND enrollments.leave_date >= DATE '2018-11-01' --their last day was on or after the snapshot date
  ) AS student_set

LEFT JOIN
  /* 2018 and 2019 MAP math scores */
    (SELECT DISTINCT ON (local_student_id)
      math.local_student_id,
      math.map_discipline,
      math.map_term,
      math.map_term_order,
      math.map_percentile,
      row_number() OVER(PARTITION BY math.local_student_id
        ORDER BY math.map_term_order ASC, math.map_percentile DESC) AS row_num

     FROM

      (SELECT
        "nwea_2018_localStudentID" AS local_student_id,
        "nwea_2018_Discipline" AS map_discipline,
        "nwea_2018_TermName" AS map_term,
        CASE WHEN "nwea_2018_TermName" = 'Spring 2017-2018' THEN 2
             WHEN "nwea_2018_TermName" = 'Winter 2017-2018' THEN 3
             WHEN "nwea_2018_TermName" = 'Fall 2017-2018' THEN 4
             ELSE 5
        END AS map_term_order,
        "nwea_2018_TestPercentile" AS map_percentile

       FROM national_assessments.nwea_2018

      UNION

      SELECT
        "nwea_2019_localStudentID" AS local_student_id,
        "nwea_2019_Discipline" AS map_discipline,
        "nwea_2019_TermName" AS map_term,
        CASE WHEN "nwea_2019_TermName" = 'Fall 2018-2019' THEN 1
             ELSE 5
        END AS map_term_order,
        "nwea_2019_TestPercentile" AS map_percentile

      FROM national_assessments.nwea_2019

      WHERE
        -- classifications should be made on fall not winter or spring of current year
        "nwea_2019_TermName" <> 'Winter 2018-2019' AND
        "nwea_2019_TermName" <> 'Spring 2018-2019'

      ) math

    WHERE map_discipline = 'Mathematics'
    ) map_math

    ON map_math.local_student_id = student_set.local_student_id

LEFT JOIN
    /* 2018 and 2019 MAP reading scores */
    (SELECT DISTINCT ON (local_student_id)
      reading.local_student_id,
      reading.map_discipline,
      reading.map_term,
      reading.map_term_order,
      reading.map_percentile,
      row_number() OVER(PARTITION BY reading.local_student_id
        ORDER BY reading.map_term_order ASC, reading.map_percentile DESC) AS row_num

     FROM
      (SELECT
        "nwea_2018_localStudentID" AS local_student_id,
        "nwea_2018_Discipline" AS map_discipline,
        "nwea_2018_TermName" AS map_term,
        CASE WHEN "nwea_2018_TermName" = 'Spring 2017-2018' THEN 2
             WHEN "nwea_2018_TermName" = 'Winter 2017-2018' THEN 3
             WHEN "nwea_2018_TermName" = 'Fall 2017-2018' THEN 4
             ELSE 5
        END AS map_term_order,
        "nwea_2018_TestPercentile" AS map_percentile

       FROM national_assessments.nwea_2018

      UNION

      SELECT
        "nwea_2019_localStudentID" AS local_student_id,
        "nwea_2019_Discipline" AS map_discipline,
        "nwea_2019_TermName" AS map_term,
        CASE WHEN "nwea_2019_TermName" = 'Fall 2018-2019' THEN 1
             ELSE 5
        END AS map_term_order,
        "nwea_2019_TestPercentile" AS map_percentile

      FROM national_assessments.nwea_2019

      WHERE
        -- classifications should be made on fall not winter or spring of current year
        "nwea_2019_TermName" <> 'Winter 2018-2019' AND
        "nwea_2019_TermName" <> 'Spring 2018-2019'

      ) reading

    WHERE map_discipline = 'Reading'
    ) AS map_reading

    ON map_reading.local_student_id = student_set.local_student_id

LEFT JOIN
  /* 2018 ELA SBAC scores - final and prelim scores are the same but only uploaded in prelim right now */
    (SELECT
      student_id,
      "sba_2018_ela_metStandard" AS sbac_ela_met_standard

    FROM state_data_wa.sba_2018_ela
    ) AS sbac_ela

    ON sbac_ela.student_id = student_set.student_id

LEFT JOIN
  /* 2018 math SBAC scores - final and prelim scores are the same but only uploaded in prelim right now */
    (SELECT
      student_id,
      "sba_2018_math_metStandard" AS sbac_math_met_standard

    FROM state_data_wa.sba_2018_math
    ) AS sbac_math

    ON sbac_math.student_id = student_set.student_id

LEFT JOIN
  /* SY18 math grades */
  (SELECT
    student_grades.student_id,
    courses.school_course_id AS math_course,
    CASE WHEN grades.is_plus IS TRUE THEN CONCAT(grades.grade_description || '+')
         WHEN grades.is_minus IS TRUE THEN CONCAT(grades.grade_description || '-')
         ELSE grades.grade_description
    END AS math_grade,
    row_number() OVER(PARTITION BY student_grades.student_id ORDER BY grades.gpa_points DESC NULLS LAST) AS row_num

  FROM student_grades
    LEFT JOIN section_grading_period_aff ON section_grading_period_aff.sgpa_id = student_grades.sgpa_id
    LEFT JOIN courses ON courses.course_id = section_grading_period_aff.course_id
    LEFT JOIN grades ON grades.grade_id = student_grades.grade_id
    LEFT JOIN grading_periods ON grading_periods.grading_period_id = section_grading_period_aff.grading_period_id
    LEFT JOIN terms ON terms.term_id = grading_periods.term_id
    LEFT JOIN sessions ON sessions.session_id = terms.session_id

  WHERE
    SUBSTRING(courses.school_course_id,1,1) = 'C' AND
    sessions.academic_year = 2018
  ) AS math_grades

  ON math_grades.student_id = student_set.student_id

LEFT JOIN
  /* SY18 ELA grades */
  (SELECT
    student_grades.student_id,
    courses.school_course_id AS ela_course,
    CASE WHEN grades.is_plus IS TRUE THEN CONCAT(grades.grade_description || '+')
         WHEN grades.is_minus IS TRUE THEN CONCAT(grades.grade_description || '-')
         ELSE grades.grade_description
    END AS ela_grade,
    row_number() OVER(PARTITION BY student_grades.student_id ORDER BY grades.gpa_points DESC NULLS LAST) AS row_num

  FROM student_grades
    LEFT JOIN section_grading_period_aff ON section_grading_period_aff.sgpa_id = student_grades.sgpa_id
    LEFT JOIN courses ON courses.course_id = section_grading_period_aff.course_id
    LEFT JOIN grades ON grades.grade_id = student_grades.grade_id
    LEFT JOIN grading_periods ON grading_periods.grading_period_id = section_grading_period_aff.grading_period_id
    LEFT JOIN terms ON terms.term_id = grading_periods.term_id
    LEFT JOIN sessions ON sessions.session_id = terms.session_id

  WHERE
    SUBSTRING(courses.school_course_id,1,1) = 'B' AND
    sessions.academic_year = 2018
  ) AS ela_grades

  ON ela_grades.student_id = student_set.student_id

WHERE
  -- Filter for highest math and reading MAP scores
  (map_reading.row_num = 1 OR map_reading.row_num IS NULL)
  AND (map_math.row_num = 1 OR map_math.row_num IS NULL)
  -- Filter for highest math and reading scores
  AND (ela_grades.row_num = 1 OR ela_grades.row_num IS NULL)
  AND (math_grades.row_num = 1 OR math_grades.row_num IS NULL)

ORDER BY site_name, last_name, first_name