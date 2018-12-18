SELECT
       q1.site_name,
       q1.stuid,
       q1.local_student_id,
       q1.last_name,
       q1.first_name,
       q1.current_grade_level,
      q1.proj_grade_level,

-- 5 columns for each department: (1) credits earned on transcripts, expected credits at this grade-level according to
-- (2) SPS and (3) A-G requirements, and the expected credits for each of these requirements next year (4 & 5).
-- These last two aid in the "projected" transcript strength calculated in Tableau against current enrollments.
-- This version is modified to include a flag for completion of Spanish 3 or AP Spanish. It was decided to count this for the SPS World Lang requirement.


       sum(hist_count) as history_credits,
       (q1.current_grade_level - 9) as sps_hist_expected,
       CASE WHEN (q1.current_grade_level - 11) < 0 THEN 0 ELSE (q1.current_grade_level - 11) END as ag_hist_expected,
       (q1.proj_grade_level - 9) as proj_sps_hist_expected,
       CASE WHEN (q1.proj_grade_level - 11) < 0 THEN 0 ELSE (q1.proj_grade_level - 11) END as proj_ag_hist_expected,

       sum(eng_count) as english_credits,
       (q1.current_grade_level - 9) as sps_eng_expected,
       CASE WHEN (q1.current_grade_level - 9) < 0 THEN 0 ELSE (q1.current_grade_level - 9) END as ag_eng_expected,
       (q1.proj_grade_level - 9) as proj_sps_eng_expected,
       CASE WHEN (q1.proj_grade_level - 9) < 0 THEN 0 ELSE (q1.proj_grade_level - 9) END as proj_ag_eng_expected,

       sum(math_count) as math_credits,
       (q1.current_grade_level - 9) as sps_math_expected,
       CASE WHEN (q1.current_grade_level - 10) < 0 THEN 0 ELSE (q1.current_grade_level - 10) END as ag_math_expected,
        (q1.proj_grade_level - 9) as proj_sps_math_expected,
       CASE WHEN (q1.proj_grade_level - 10) < 0 THEN 0 ELSE (q1.proj_grade_level - 10) END as proj_ag_math_expected,

       sum(sci_count) as science_credits,
       (q1.current_grade_level - 9) as sps_sci_expected,
       CASE WHEN (q1.current_grade_level - 11) < 0 THEN 0 ELSE (q1.current_grade_level - 11) END as ag_sci_expected,
       (q1.proj_grade_level - 9) as proj_sps_sci_expected,
       CASE WHEN (q1.proj_grade_level - 11) < 0 THEN 0 ELSE (q1.proj_grade_level - 11) END as proj_ag_sci_expected,

       sum(wrldlang_count) as wrldlang_credits,
        sum(wrldlang3plus_count) >= 1 as wrldlang_mastery,
       CASE WHEN (q1.current_grade_level - 11) < 0 THEN 0 ELSE (q1.current_grade_level - 11) END as sps_wrldlang_expected,
       CASE WHEN (q1.current_grade_level - 11) < 0 THEN 0 ELSE (q1.current_grade_level - 11) END as ag_wrld_lang_expected,
       CASE WHEN (q1.proj_grade_level - 11) < 0 THEN 0 ELSE (q1.proj_grade_level - 11) END as proj_sps_wrldlang_expected,
       CASE WHEN (q1.proj_grade_level - 11) < 0 THEN 0 ELSE (q1.proj_grade_level - 11) END as proj_ag_wrld_lang_expected,

       sum(uc_elec_count) as uc_elec_credits,

       sum(vpa_count) as vpa_credits,
       sum(vpa_count) >= 1 as vpa_met


FROM
(SELECT sites.site_name,
             msc.student_id                                                          AS stuid,
             students.local_student_id,
             students.last_name,
             students.first_name,
             (msc.grade_level_id - 1)                                                AS current_grade_level,
             (msc.grade_level_id)                                                AS proj_grade_level,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'A%'),0) as hist_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'B%'),0) as eng_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'C%'),0) as math_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'D%'),0) as sci_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'E%'),0) as wrldlang_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'E3%' OR sgt.school_course_id LIKE 'E4%'),0) as wrldlang3plus_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'F%'),0) as vpa_count,
             coalesce(sum(sgt.credits_received) FILTER (WHERE sgt.school_course_id LIKE 'G%'),0) as uc_elec_count,
            coalesce(sum(sgt.credits_possible) FILTER (WHERE sgt.grade_level_id = 10),0) as ninthrecs,
       coalesce(sum(sgt.credits_possible) FILTER (WHERE sgt.grade_level_id = 11),0) as tenthrecs,
       coalesce(sum(sgt.credits_possible) FILTER (WHERE sgt.grade_level_id = 12),0) as eleventhrecs,
       coalesce(sum(sgt.credits_possible) FILTER (WHERE sgt.grade_level_id = 13),0) as twelfthrecs


      FROM matviews.ss_current msc
             LEFT JOIN matviews.student_grades_transcript sgt on sgt.student_id = msc.student_id
                                                                   AND sgt.grade_level_id >= 10
                                                                   AND sgt.credits_possible > 0
                                                                   AND sgt.is_repeat IS FALSE
                                                                   AND (sgt.school_course_id LIKE 'A%' OR
                                                                        sgt.school_course_id LIKE 'B%' OR
                                                                        sgt.school_course_id LIKE 'C%' OR
                                                                        sgt.school_course_id LIKE 'D%' OR
                                                                        sgt.school_course_id LIKE 'E%' OR
                                                                        sgt.school_course_id LIKE 'F%' OR
                                                                        sgt.school_course_id LIKE 'G%')
             LEFT JOIN students on msc.student_id = students.student_id
             LEFT JOIN courses on sgt.course_id = courses.course_id
             LEFT JOIN departments on courses.department_id = departments.department_id
             LEFT JOIN sites on msc.site_id = sites.site_id

      WHERE length(cast(msc.site_id as text)) < 3
        AND (courses.transcript_inclusion IS NULL OR courses.transcript_inclusion IS TRUE)
AND msc.grade_level_id >= 10


    --     AND local_student_id = '11951'

      GROUP BY sites.site_name,
               msc.student_id,
               students.local_student_id,
               students.last_name,
               students.first_name,
               msc.grade_level_id,
               sgt.credits_received,
               sgt.grade_level_id,
               sgt.school_course_id

      ORDER BY sites.site_name,
               msc.grade_level_id,
               students.last_name,
               students.first_name,
               sgt.school_course_id,
               sgt.grade_level_id) q1

GROUP BY
         q1.site_name,
       q1.stuid,
       q1.local_student_id,
       q1.last_name,
       q1.first_name,
       q1.current_grade_level,
         q1.proj_grade_level

ORDER BY
         site_name,
         current_grade_level,
         last_name,
         first_name