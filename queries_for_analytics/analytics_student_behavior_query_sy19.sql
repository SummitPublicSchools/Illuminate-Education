-- R&D Behavior query
WITH student_set AS (
  SELECT
    enrollments.student_id
  , enrollments.grade_level_id - 1 AS grade_level
  , sessions.academic_year
  , enrollments.entry_date
  , enrollments.leave_date
  , sessions.site_id
  , terms.start_date AS term_start_date
  , terms.end_date AS term_end_date
  FROM
    -- for selecting school year student set
    student_session_aff AS enrollments
    LEFT JOIN sessions ON enrollments.session_id = sessions.session_id
    LEFT JOIN terms ON sessions.session_id = terms.session_id

  WHERE
    -- student set
    sessions.academic_year = 2019
    AND term_name = 'Year'
    AND sessions.site_id IN(1,2,3,4,5,6,7,8,11,12,13)
    -- Remove the following if you want all student enrollments for this academic year
    -- AND DATE 'today' BETWEEN enrollments.entry_date AND enrollments.leave_date

  ORDER BY student_id
)

SELECT
  incidents.incident_id
  , students.local_student_id AS student_id
  , incidents.incident_date::DATE
  , student_set.academic_year
  , codes.behavior_consequences.code_translation AS consequence_type
  , behavior.incidents.is_major
  , codes.behavior_descriptions.code_translation AS incident
  , codes.behavior_violations.code_translation AS violation_type
  , codes.behavior_participants_types.code_translation AS participant_type
  , users.email1 AS assigned_by
  , codes.behavior_locations.code_translation AS location
  , NOW()::DATE AS as_of

FROM behavior.incidents
  LEFT JOIN codes.behavior_descriptions ON behavior.incidents.description_id = codes.behavior_descriptions.code_id
  LEFT JOIN behavior.participants ON behavior.incidents.incident_id = behavior.participants.incident_id
  LEFT JOIN students ON behavior.participants.student_id = students.student_id
  LEFT JOIN codes.behavior_participants_types
    ON behavior.participants.participant_type_id = codes.behavior_participants_types.code_id
  LEFT JOIN behavior.violations ON behavior.incidents.primary_violation_id = behavior.violations.violation_id
  LEFT JOIN codes.behavior_violations ON behavior.violations.violation_type_id = codes.behavior_violations.code_id
  LEFT JOIN users ON behavior.incidents.referred_by = users.user_id
  LEFT JOIN codes.behavior_locations ON behavior.incidents.location_id = codes.behavior_locations.code_id
  LEFT JOIN behavior.consequences ON behavior.participants.participant_id = behavior.consequences.participant_id
  LEFT JOIN codes.behavior_consequences
    ON behavior.consequences.consequence_type_id = codes.behavior_consequences.code_id
  INNER JOIN student_set ON behavior.participants.student_id = student_set.student_id

WHERE behavior.incidents.incident_date BETWEEN student_set.term_start_date AND student_set.term_end_date

ORDER BY incident_date DESC;