/*
  Students with Duplicate Addresses

  This query will pull records for students that have addresses that are similar enough to
  potentially be duplicates. A returned match here could mean at least one of the following
  situations has occurred:
  1. A student has the mother and father in two different households with the same address
  2. A household has a street address and separate mailing address that are similar enough that
     they should not be separate
  3. A student has a same address in 'Other' contacts as well as one of the main households

 */
WITH
  student_households_with_dwellings AS (
    SELECT DISTINCT
      stu.student_id || '_' || household_id || '_' || dwelling_id AS shd_uid,
      stu.local_student_id,
      stu.student_id,
      household_id,
      dwelling_id,
      address,
      address_2

    FROM
      matviews.ss_current
      LEFT JOIN public.students stu USING (student_id)
      LEFT JOIN contacts.students_contact_info
        ON matviews.ss_current.student_id = contacts.students_contact_info.student_id
      LEFT JOIN contacts.household_dwelling_aff hda USING (household_id)
      LEFT JOIN contacts.dwellings USING (dwelling_id)

    WHERE
      dwelling_id IS NOT NULL --AND
      --hda.is_primary IS TRUE
  )

SELECT DISTINCT
  sites.site_name,
  stu.local_student_id,
  stu.last_name,
  stu.first_name,
  curr_stu.grade_level_id - 1 AS grade,
  shd1.address AS address_a,
  shd2.address AS address_b,
  shd1.household_id AS household_id_a,
  shd2.household_id AS household_id_b,
  shd1.dwelling_id AS dwelling_id_a,
  shd2.dwelling_id AS dwelling_id_b


FROM
  -- get combinations of household addresses
  student_households_with_dwellings shd1
  INNER JOIN
  student_households_with_dwellings shd2
  ON shd1.shd_uid < shd2.shd_uid

  LEFT JOIN public.students stu
    ON shd1.student_id = stu.student_id

  INNER JOIN matviews.ss_current curr_stu
    ON stu.student_id = curr_stu.student_id

  LEFT JOIN sites USING (site_id)

WHERE
  shd1.address LIKE shd2.address AND
  shd1.student_id = shd2.student_id

  AND sites.site_name NOT IN ('SPS Tour', 'Summit Public Schools')
