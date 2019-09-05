/* This query identifies all currently enrolled students at Shasta and Denali who qualify for Title I.
Meeting any of the following criteria will qualify a student:
- Grade of C+ or below in math or English
- Highest MAP Math or Reading score within the past year is below 50th percentile
- Below proficient on last year's SBAC administration (if applicable)
This query pulls all of the relevant criteria and determines eligibility. Students may be duplicated if they had more
than one math or English course in the previous school year.
 */

SELECT
  student_set.site_name,
  student_set.local_student_id,
  student_set.last_name,
  student_set.first_name,
  student_set.grade_level,
  math_grades.math_course,
  math_grades.math_grade AS math_grade,
  ela_grades.ela_course,
  ela_grades.ela_grade,
  max_map_math.map_term AS max_map_math_term,
  max_map_math.map_percentile AS max_map_math_percentile,
  max_map_reading.map_term AS max_map_reading_term,
  max_map_reading.map_percentile AS max_map_reading_percentile,
  sbac_math.sbac_math_level,
  sbac_ela.sbac_ela_level,
  CASE WHEN math_grade IN ('F', 'D-', 'D', 'D+', 'C-', 'C', 'C+', 'INCOMPLETE') THEN TRUE
       WHEN ela_grade IN  ('F', 'D-', 'D', 'D+', 'C-', 'C', 'C+', 'INCOMPLETE') THEN TRUE
       WHEN max_map_math.map_percentile < 50 THEN TRUE
       WHEN max_map_reading.map_percentile < 50 THEN TRUE
       WHEN sbac_math_level IN ('Standard Not Met', 'Standard Nearly Met') THEN TRUE
       WHEN sbac_ela_level IN ('Standard Not Met', 'Standard Nearly Met') THEN TRUE
       ELSE FALSE
  END AS title_i

FROM
  /* student set */
  (SELECT
    sites.site_name,
    students.student_id,
    students.local_student_id,
    students.last_name,
    students.first_name,
    enrollments.grade_level_id - 1 as grade_level

  FROM
    student_session_aff AS enrollments

  LEFT JOIN students ON students.student_id = enrollments.student_id
  LEFT JOIN sessions ON sessions.session_id = enrollments.session_id
  LEFT JOIN sites ON sites.site_id = sessions.site_id

  WHERE
    /* change session ids for different sites or academic years */
    enrollments.session_id in (233, 236) AND
    enrollments.leave_date > DATE 'today'
  ) student_set

LEFT JOIN
  /* SY18 math grades */
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
    sessions.academic_year = 2018
  ) math_grades

  ON math_grades.student_id = student_set.student_id

LEFT JOIN
  /* SY18 ELA grades */
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
    sessions.academic_year = 2018
  ) ela_grades

  ON ela_grades.student_id = student_set.student_id

LEFT JOIN
  /* 2018 and 2019 MAP math scores */
    (SELECT DISTINCT ON (student_id)
      map_math.student_id,
      map_math.map_discipline,
      map_math.map_term,
      map_math.map_percentile

     FROM

      (SELECT
        student_id,
        "nwea_2018_Discipline" AS map_discipline,
        "nwea_2018_TermName" AS map_term,
        "nwea_2018_TestPercentile" AS map_percentile

       FROM national_assessments.nwea_2018

      UNION

      SELECT
        student_id,
        "nwea_2019_Discipline" AS map_discipline,
        "nwea_2019_TermName" AS map_term,
        "nwea_2019_TestPercentile" AS map_percentile

      FROM national_assessments.nwea_2019

      ) map_math

    WHERE map_discipline = 'Mathematics'

    ORDER BY student_id, map_percentile DESC
    ) max_map_math

    ON max_map_math.student_id = student_set.student_id

LEFT JOIN
    /* 2018 and 2019 MAP reading scores */
    (SELECT DISTINCT ON (student_id)
      map_reading.student_id,
      map_reading.map_discipline,
      map_reading.map_term,
      map_reading.map_percentile

     FROM
      (SELECT
        student_id,
        "nwea_2018_Discipline" AS map_discipline,
        "nwea_2018_TermName" AS map_term,
        "nwea_2018_TestPercentile" AS map_percentile

       FROM national_assessments.nwea_2018

      UNION

      SELECT
        student_id,
        "nwea_2019_Discipline" AS map_discipline,
        "nwea_2019_TermName" AS map_term,
        "nwea_2019_TestPercentile" AS map_percentile

      FROM national_assessments.nwea_2019

      ) map_reading

    WHERE map_discipline = 'Reading'

    ORDER BY student_id, map_percentile DESC
    ) max_map_reading

    ON max_map_reading.student_id = student_set.student_id

LEFT JOIN
  /* ELA SBAC scores */
    (SELECT
      student_id,
      "caaspp_2018_ela_performanceLevelText" AS sbac_ela_level

    FROM state_data_ca.caaspp_2018_ela

    WHERE "caaspp_2018_assessType" = 'Summative (Final)'
    ) sbac_ela

    ON sbac_ela.student_id = student_set.student_id

LEFT JOIN
  /* math SBAC scores */
    (SELECT
      student_id,
      "caaspp_2018_math_performanceLevelText" AS sbac_math_level

    FROM state_data_ca.caaspp_2018_math

    WHERE "caaspp_2018_assessType" = 'Summative (Final)'
    ) sbac_math

    ON sbac_math.student_id = student_set.student_id


ORDER BY
  site_name,
  grade_level,
  local_student_id
