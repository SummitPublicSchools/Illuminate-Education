-- This counts transcript course records by grade level, making sure that there are records from each grade level prior to the current one.
-- The boolean in the last column evaluates whether a grade level is missing from the transcript, implying that transfer grades have not been entered.

SELECT
       site,
       stuid,
       local_id,
       credits_per_gl.last_name,
       credits_per_gl.first_name,
       credits_per_gl.current_grade,
       allgradesintranscript,
       credits_per_gl.ninthrecs,
       credits_per_gl.tenthrecs,
       credits_per_gl.eleventhrecs,
       credits_per_gl.twelfthrecs

FROM
    (SELECT *,
  CASE WHEN current_grade = 12 THEN (ninthrecs > 0 AND tenthrecs > 0 AND eleventhrecs > 0) ELSE
    CASE WHEN current_grade = 11 THEN (ninthrecs > 0 AND tenthrecs > 0) ELSE
      CASE WHEN current_grade = 10 THEN ninthrecs > 0 ELSE
          CASE WHEN current_grade = 9 THEN TRUE ELSE FALSE
              END
          END
    END
  END AS allgradesintranscript
FROM
  (SELECT
    sites.site_name                AS site,
    students.student_id            AS stuid,
    students.local_student_id      AS local_id,
    students.last_name             AS last_name,
    students.first_name            AS first_name,
    (sscurrent.grade_level_id - 1) AS current_grade,
    SUM (CASE WHEN sgt.grade_level_id = 10 THEN sgt.credits_possible ELSE 0 END) as ninthrecs,
    SUM (CASE WHEN sgt.grade_level_id = 11 THEN sgt.credits_possible ELSE 0 END) as tenthrecs,
    SUM (CASE WHEN sgt.grade_level_id = 12 THEN sgt.credits_possible ELSE 0 END) as eleventhrecs,
    SUM (CASE WHEN sgt.grade_level_id = 13 THEN sgt.credits_possible ELSE 0 END) as twelfthrecs

  FROM
    matviews.ss_current AS sscurrent

  LEFT JOIN matviews.student_grades_transcript sgt ON
        (sscurrent.student_id = sgt.student_id
            AND (sgt.school_course_id LIKE 'A%' OR sgt.school_course_id LIKE 'B%' OR sgt.school_course_id LIKE 'C%' OR
      sgt.school_course_id LIKE 'D%' OR sgt.school_course_id LIKE 'E%' OR sgt.school_course_id LIKE 'F%' OR
      sgt.school_course_id LIKE 'G%'))
  LEFT JOIN sites ON sites.site_id = sscurrent.site_id
  LEFT JOIN students ON students.student_id = sscurrent.student_id

  WHERE
    sscurrent.site_id < 100
    AND sscurrent.grade_level_id >= 10
--
--   AND    students.local_student_id = '11951'

  GROUP BY
    sites.site_name
    , students.student_id
    , students.local_student_id
    , students.last_name
    , students.first_name
    , sscurrent.grade_level_id)
    AS glcounts


  ORDER BY
   site,
   current_grade,
   last_name,
   first_name) as credits_per_gl