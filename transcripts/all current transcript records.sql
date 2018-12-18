-- Pull of all student transcript records for current CA students.

SELECT sites.site_name,
       students.local_student_id,
       students.last_name,
       students.first_name,
       (msc.grade_level_id - 1) as current_grade_level,
       sgt.academic_year        AS tsc_year,
       sgt.grade_level          as tsc_grade_level,
       departments.department_name,
       courses.school_course_id,
       courses.short_name,
       sgt.credits_possible,
       sgt.credits_received,
       grades.grade

FROM matviews.ss_current msc
       LEFT JOIN matviews.student_grades_transcript sgt on sgt.student_id = msc.student_id
       LEFT JOIN students on msc.student_id = students.student_id
       LEFT JOIN courses on sgt.course_id = courses.course_id
       LEFT JOIN departments on courses.department_id = departments.department_id
       LEFT JOIN sites on msc.site_id = sites.site_id
       LEFT JOIN grades on sgt.grade_id = grades.grade_id

WHERE length(cast(msc.site_id as text)) < 3
  AND (courses.transcript_inclusion IS NULL OR courses.transcript_inclusion IS TRUE)
  AND sgt.grade_level_id >= 10
  AND sgt.credits_possible > 0
  AND sgt.is_repeat IS TRUE
--   AND (grades.grade = 'I' OR grades.grade = 'F')


    -- AND local_student_id = '70008'

ORDER BY msc.site_id,
         msc.grade_level_id,
         students.last_name,
         students.first_name,
         sgt.grade_level_id