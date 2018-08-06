    SELECT DISTINCT
     local_student_id,
     state_student_id,
     stu.student_id,
     stu.first_name,
     stu.last_name,
     sites.site_name AS site,
     grade_level_id - 1 AS grade_level,
     stu.birth_date,
     -- program_aff.student_program_id,
     -- program_codes.code_id,
     program_codes.code_key AS program_code_key,
     program_codes.code_translation,
     stu.migrant_ed_student_id,
     program_aff.start_date,
     program_aff.eligibility_start_date,
     program_aff.end_date,
     program_aff.eligibility_end_date
    FROM
     -- Start with enrollment records (according to Illuminate, this is supposed
     -- to be the authoritative table for enrollment records)
     public.student_session_aff AS enrollments
     LEFT JOIN public.sessions AS sessions ON enrollments.session_id = sessions.session_id
     LEFT JOIN public.students stu ON enrollments.student_id = stu.student_id
     LEFT JOIN public.sites AS sites ON sessions.site_id = sites.site_id
     LEFT JOIN public.student_program_aff AS program_aff ON enrollments.student_id = program_aff.student_id
     LEFT JOIN codes.student_programs AS program_codes ON program_aff.student_program_id = program_codes.code_id

    WHERE
     -- This will get you all students who were enrolled in 17-18 even if they have withdrawn
     enrollments.entry_date >= '08-15-2017' AND
     enrollments.leave_date >= '06-07-2018' AND
     academic_year = 2018
      AND(program_aff.start_date >= '08-01-2017' OR
     program_aff.eligibility_start_date >='08-01-2017' OR
     program_aff.end_date IS NULL) AND
     --Codes for Migrant, Military, and Homeless
     program_codes.code_key IN ('131','135','192')
    ORDER BY  code_translation