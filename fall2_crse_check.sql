/* For Fall 2 Data Checks: CRSE

The query pulls all active sections in Census Day. Each section must have a teacher with a valid state_id or 9999999999
and the proper state_course_id. This is mainly for checking your CRSE file but will be useful to run prior to SDEM and SASS submissions.

How to use to check your Illuminate generated CRSE file:
- Check that teachers without SEIDs are tutors/teaching residents/secondary teachers and are excluded from state reporting
- Check that all project time sections are included
- Check state_course_ids vs. CALPADS state course id codes
- Check all sections have an education_service code (most, if not all, will be 4)
- Check all sections have an instructional_strategy
- Check that all SEIDs are valid length (10 characters)
- Check all reported staff have staff_education_level
- Check that modified courses have a non_standard_instructional_level (10 for Remedial)

Things to add:
- UC/CSU requirements
*/

SELECT
  sites.site_name,
  users.last_name,
  users.state_id AS SEID,
  CASE WHEN
    length(users.state_id) = 10
    THEN TRUE
    ELSE FALSE
  END AS valid_seid_length,
  users.exclude_from_state_reporting,
  users.staff_education_level,
  courses.short_name,
  dep.department_name,
  courses.course_id AS state_course_id,
  courses.education_service,
  instr.state_id AS instructional_strategy_state_code,
  nsil.state_id AS non_standard_instructional_level_state_code


FROM
  sections

LEFT JOIN section_teacher_aff teachaff ON sections.section_id = teachaff.section_id
LEFT JOIN users ON teachaff.user_id = users.user_id
LEFT JOIN section_course_aff sca ON sections.section_id = sca.section_id
LEFT JOIN courses ON sca.course_id = courses.course_id
LEFT JOIN section_term_aff termaff ON sections.section_id = termaff.section_id
LEFT JOIN terms ON termaff.term_id = terms.term_id
LEFT JOIN sessions ON terms.session_id = sessions.session_id
LEFT JOIN sites ON sessions.site_id = sites.site_id
LEFT JOIN departments dep ON courses.department_id = dep.department_id
LEFT JOIN codes.non_standard_instructional_level nsil ON nsil.code_id = courses.non_standard_instructional_level
LEFT JOIN codes.instructional_strategy instr ON instr.code_id = courses.instructional_strategy

WHERE
  sessions.academic_year = 2018
-- Edit this to the proper Census Day :
  AND (teachaff.end_date >= '2017-10-04'
    OR teachaff.end_date is NULL)
-- Edit this to choose a site:
  AND sites.site_name LIKE '%Preparatory%'
  AND courses.exclude_from_state_reporting is FALSE
-- If you chose to report expeditions or PLTs, comment out:
  AND courses.department_id NOT IN (44)
-- Edit this to the proper Census Day:
  AND section_is_active(sections.section_id,'2017-10-04') is TRUE

ORDER BY users.state_id
