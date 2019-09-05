-- Pull of all student transcript records for current CA students.

SELECT sites.site_name,
       students.local_student_id,
       students.last_name,
       students.first_name,
       (cast(msa.grade_level_id AS int) - 1) as current_grade_level,
       sgt.academic_year        AS tsc_year,
       sgt.grade_level          as tsc_grade_level,
       departments.department_name,
       courses.school_course_id,
       courses.short_name,
       sgt.credits_possible,
       sgt.credits_received,
       grades.grade

FROM matviews.student_term_aff msta
       LEFT JOIN matviews.ss_any msa on msta.student_id = msa.student_id
       LEFT JOIN terms on msta.term_id = terms.term_id
       LEFT JOIN sessions on terms.session_id = sessions.session_id
       LEFT JOIN matviews.student_grades_transcript sgt on sgt.student_id = msta.student_id
       LEFT JOIN students on msta.student_id = students.student_id
       LEFT JOIN courses on sgt.course_id = courses.course_id
       LEFT JOIN departments on courses.department_id = departments.department_id
       LEFT JOIN sites on sessions.site_id = sites.site_id
       LEFT JOIN grades on sgt.grade_id = grades.grade_id

WHERE sites.site_id < 100
  AND (courses.transcript_inclusion IS NULL OR courses.transcript_inclusion IS TRUE)
  AND sgt.grade_level_id >= 10
  AND sgt.credits_possible > 0
-- --   AND sgt.is_repeat IS TRUE
--   AND msta.grade_level_id = 13
--   AND msa.grade_level_id = '13'
--   AND sessions.academic_year = 2018
--   AND (grades.grade = 'I' OR grades.grade = 'F')


    -- AND local_student_id = '70008'

ORDER BY msa.site_id,
         msta.grade_level_id,
         students.last_name,
         students.first_name,
         sgt.grade_level_id