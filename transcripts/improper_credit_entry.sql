-- This pulls a list of all transcript records where:
--    The student has a passing grade.
--    The credits received do not match the credits attempted, or is null.
--    The course is not repeated later.
-- The assumption is that these are improperly-entered transfer credits.

SELECT * FROM
  (SELECT
        students.local_student_id                 AS local_id,
        students.last_name,
        students.first_name,
        sites.site_name                           AS site,
        (matviews.ss_current.grade_level_id - 1)  AS current_grade,
        departments.department_name,
        courses.school_course_id,
        courses.short_name,
        student_grades_transcript_view.academic_year,
        grades.grade,
        student_grades_transcript_view.credits_possible AS attempted,
        student_grades_transcript_view.credits_received as received,
        student_grades_transcript_view.is_repeat,
        CASE WHEN  (grades.grade = 'F' OR grades.grade = 'I' OR grades.grade LIKE 'D%' OR grades.grade = 'W' OR grades.grade LIKE 'N%' OR grades.grade = 'E') THEN FALSE ELSE
          CASE WHEN (student_grades_transcript_view.credits_possible - student_grades_transcript_view.credits_received) <> 0 THEN TRUE ELSE
            CASE WHEN student_grades_transcript_view.credits_received IS NULL THEN TRUE ELSE FALSE END END END AS credit_error

      FROM matviews.ss_current

        LEFT JOIN students ON matviews.ss_current.student_id = students.student_id
        LEFT JOIN sites ON sites.site_id = matviews.ss_current.site_id
        LEFT JOIN student_grades_transcript_view
          ON student_grades_transcript_view.student_id = matviews.ss_current.student_id
        LEFT JOIN courses ON courses.course_id = student_grades_transcript_view.course_id
        LEFT JOIN departments ON departments.department_id = courses.department_id
        LEFT JOIN grades on grades.grade_id = student_grades_transcript_view.grade_id

      WHERE matviews.ss_current.site_id <> 9999999
      AND academic_year IS NOT NULL
      AND is_repeat IS FALSE) as transcript_pull
WHERE credit_error is TRUE
;
