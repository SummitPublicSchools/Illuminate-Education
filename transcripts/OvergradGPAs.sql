-- This generates an upload file for adding GPAs for HS students to Overgrad.
SELECT
  sites.site_name school
  , students.local_student_id local_id
  , CASE WHEN student_gpa.gpa_calculation_id = 1 THEN 'unweighted' ELSE
      CASE WHEN student_gpa.gpa_calculation_id = 2 THEN 'weighted_uccsu' ELSE
          CASE WHEN student_gpa.gpa_calculation_id = 6 THEN 'weighted_10-12' ELSE
              CASE WHEN student_gpa.gpa_calculation_id = 3 THEN 'weighted_9-12' ELSE NULL END END END END AS type
  , student_gpa.gpa
  , student_gpa.timestamp as gpa_date

FROM
  matviews.ss_current

LEFT JOIN sites
    ON sites.site_id = matviews.ss_current.site_id
LEFT JOIN students
    ON students.student_id = matviews.ss_current.student_id
LEFT JOIN matviews.student_term_aff
    ON student_term_aff.student_id = matviews.ss_current.student_id
LEFT JOIN terms
    ON terms.term_id = matviews.student_term_aff.term_id
LEFT JOIN student_gpa
    ON students.student_id = student_gpa.student_id
LEFT JOIN gpa_calculations
    ON student_gpa.gpa_calculation_id = gpa_calculations.gpa_calculation_id

WHERE
  matviews.ss_current.site_id < 100
  AND matviews.ss_current.grade_level_id >= 12
  AND student_gpa.academic_year is NULL
  AND terms.term_type = 1
  AND terms.term_name = 'Year'
  AND student_gpa.gpa_calculation_id IN (1, 2)
  AND student_gpa.grading_period_id IS NULL
  AND (terms.end_date > now() OR terms.end_date IS NULL)

-- AND local_student_id = '20947'

GROUP BY
  sites.site_name
  , students.local_student_id
  , student_gpa.gpa_calculation_id
  , student_gpa.gpa
  , student_gpa.timestamp

ORDER BY
  sites.site_name,
  local_student_id