/*
This query pulls all current students at a site with a count of their total daily absences, total class absences, and
 total tardies for the year. This query was QA'ed for CA schools and should be reevaluated in its use for WA schools.

 Examples of use:
 - Custom report in Illuminate for sites to use in mail merge

 Instructions:
 - Modify line 37 for desired site
 - Modify line 38 to first day of school in AY
 - Modify line 65 to first day of school in AY
 
 */


WITH flags_by_class AS (
    SELECT
      current.student_id,
      current.grade_level_id -1 AS grade,
      current.site_id,
      SUM(CASE WHEN
        af.flag_text in ('Tardy', 'Truant Tardy')
        THEN 1
          ELSE 0
          END) AS tardy_count,
      SUM(CASE WHEN
        af.flag_text IN ('Unexcused Absent', 'Absent')
        THEN 1
          ELSE 0
          END) AS unexcused_absences_per_class

    FROM matviews.ss_current current
      LEFT JOIN public.section_student_aff ssa ON ssa.student_id = current.student_id
      LEFT JOIN public.student_attendance satt ON satt.ssa_id = ssa.ssa_id
      LEFT JOIN public.attendance_flags af ON af.attendance_flag_id = satt.attendance_flag_id

    WHERE current.site_id = 2 --Tahoma
          AND satt."date" >= '2017-08-15'

    GROUP BY current.student_id,
      current.grade_level_id,
      current.site_id
)

SELECT
  stud.local_student_id,
  fbc.grade,
  stud.first_name,
  stud.last_name,
  SUM(CASE WHEN
    -- public.attendance_flags : 2 - "Absent" 3 - "Unexcused Absent'
    ada.attendance_flag_id IN (2, 3)
    THEN 1
      ELSE 0
      END) AS unexcused_absences_per_day,
  fbc.tardy_count,
  fbc.unexcused_absences_per_class

FROM flags_by_class fbc
  LEFT JOIN attendance.daily_records_ada ada ON ada.student_id = fbc.student_id
  LEFT JOIN public.sites ON sites.site_id = ada.site_id
  LEFT JOIN public.students stud ON fbc.student_id = stud.student_id

WHERE
  ada.date >= '2017-08-15'
  AND ada.date <= current_date

GROUP BY
  sites.site_name,
  stud.local_student_id,
  stud.last_name,
  stud.first_name,
  fbc.grade,
  fbc.tardy_count,
  fbc.unexcused_absences_per_class

ORDER BY
  fbc.unexcused_absences_per_class DESC

