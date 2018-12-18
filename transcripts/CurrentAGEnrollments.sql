-- This counts the number of courses that each currently-enrolled student is enrolled in by A-G category.
SELECT local_id, last_name, first_name, site, current_grade
  , sum(hist_enrolled) hist_enr_cred
  , sum(eng_enrolled) eng_enr_cred
  , sum(math_enrolled) math_enr_cred
  , sum(science_enrolled) sci_enr_cred
  , sum(forlang_enrolled) forlang_enr_cred
  , sum(vpa_enrolled) vpa_enr_cred



FROM
  (SELECT
    students.local_student_id                 AS local_id,
    students.last_name,
    students.first_name,
    sites.site_name AS site,
    (matviews.ss_current.grade_level_id - 1)  AS current_grade,
    CASE WHEN
      left(courses.school_course_id,1) = 'A' THEN 1 ELSE 0 END AS hist_enrolled,
    CASE WHEN
      left(courses.school_course_id,1) = 'B' THEN 1 ELSE 0 END AS eng_enrolled,
    CASE WHEN
      left(courses.school_course_id,1) = 'C' THEN 1 ELSE 0 END AS math_enrolled,
    CASE WHEN
      left(courses.school_course_id,1) = 'D' THEN 1 ELSE 0 END AS science_enrolled,
    CASE WHEN
      left(courses.school_course_id,1) = 'E' THEN 1 ELSE 0 END AS forlang_enrolled,
    CASE WHEN
        left(courses.school_course_id,1) = 'F' THEN 1 ELSE 0 END AS vpa_enrolled,
  CASE WHEN
        left(courses.school_course_id,1) = 'G' THEN 1 ELSE 0 END AS ucelec_enrolled,
    students.school_enter_date


  FROM matviews.ss_current

  LEFT JOIN students on students.student_id = matviews.ss_current.student_id
  LEFT JOIN sites on sites.site_id = matviews.ss_current.site_id
  LEFT JOIN section_student_aff on section_student_aff.student_id = matviews.ss_current.student_id
  LEFT JOIN courses on courses.course_id = section_student_aff.course_id
  LEFT JOIN section_term_aff on section_term_aff.section_id = section_student_aff.section_id
  LEFT JOIN terms on section_term_aff.term_id = terms.term_id
  LEFT JOIN matviews.student_grades_transcript on matviews.student_grades_transcript.student_id = matviews.ss_current.student_id

  WHERE sites.site_id < 100
    AND (terms.start_date < now() AND terms.end_date > now())
    AND (section_student_aff.leave_date > now() OR section_student_aff.leave_date IS NULL)
    AND matviews.ss_current.grade_level_id >= 10

  --   AND students.local_student_id = '11504'

  GROUP BY local_id,
    students.last_name,
    students.first_name,
    site,
    current_grade,
    students.school_enter_date,
    section_student_aff.leave_date,
    section_student_aff.course_id,
    courses.school_course_id,
    hist_enrolled,
    eng_enrolled,
    math_enrolled,
    science_enrolled,
    forlang_enrolled,
    vpa_enrolled

  ORDER BY students.local_student_id) as longlistcounters

WHERE
  hist_enrolled > 0 OR eng_enrolled > 0 OR math_enrolled > 0 OR science_enrolled > 0 OR forlang_enrolled > 0 OR vpa_enrolled > 0

GROUP BY
  local_id, last_name, first_name, site, current_grade

ORDER BY
         site, current_grade, last_name, first_name
;