SELECT
/* Description

*/

sites.site_name,
stud.local_student_id,
stud.last_name,
stud.first_name,
ss.grade_level_id - 1 as grade,
houses.house_name as house,

dor.code_key as dor_code,
dor.code_translation as dor_translation

FROM matviews.ss_current AS ss

LEFT JOIN students stud on stud.student_id = ss.student_id
left join sites on sites.site_id = ss.site_id
left join student_house_aff house_aff on house_aff.student_id = ss.student_id
left join houses on houses.house_id = house_aff.house_id

left join student_transfers st on st.student_id = ss.student_id and st.start_date >= '2016-08-16'
left join codes.district_of_residence dor on dor.code_id = st.from_district_id

WHERE
ss.site_id not in (9999999, 9999998)
and
dor.code_key is null
