SELECT 
    s.academic_year
    , sch.site_name
    , sch.site_id
    , sta.student_id
    , local_student_id
    , state_student_id
    , gl.short_name AS grade_level
    , entry_date
    , leave_date
    , st.transfer_academic_year
    , st.start_date AS transfer_start_date
    , st.end_date AS transfer_end_date
    , dor.code_key AS transfer_district_id
    , dor.code_translation AS transfer_district_name
    , cstr.code_key AS transfer_reason
    , csta.code_key AS transfer_status

FROM matviews.student_term_aff AS sta

LEFT JOIN students AS stu ON sta.student_id = stu.student_id
LEFT JOIN grade_levels AS gl ON sta.grade_level_id = gl.grade_level_id
LEFT JOIN terms AS t ON sta.term_id = t.term_id
LEFT JOIN sessions AS s ON t.session_id = s.session_id
LEFT JOIN sites AS sch ON s.site_id = sch.site_id
LEFT JOIN student_transfers AS st ON sta.student_id = st.student_id
    AND s.academic_year = st.transfer_academic_year
    --AND sch.site_id = st.to_school_id
LEFT JOIN  codes.district_of_residence AS dor ON st.from_district_id = dor.code_id
LEFT JOIN codes.student_transfer_reason AS cstr ON st.transfer_reason_id = cstr.code_id
LEFT JOIN codes.student_transfer_status AS csta ON st.transfer_status_id = csta.code_id

WHERE s.academic_year = 2018
    AND t.term_name = 'Year'
    AND sch.site_id < 20

ORDER BY sch.site_name, local_student_id, entry_date, leave_date