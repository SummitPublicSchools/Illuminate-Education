WITH student_set AS (
  SELECT
    enrollments.student_id
  , enrollments.grade_level_id - 1 AS grade_level
  , sessions.academic_year
  , enrollments.entry_date
  , enrollments.leave_date
  , sessions.site_id
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
    AND DATE 'today' BETWEEN enrollments.entry_date AND enrollments.leave_date

  ORDER BY student_id
), student_mentors AS (
  SELECT DISTINCT
    student_set.student_id
    , users.user_id
    , users.last_name
    , users.first_name
    , users.email1 AS email
  FROM student_set
    LEFT JOIN section_student_aff ON student_set.student_id = section_student_aff.student_id
    LEFT JOIN sections ON section_student_aff.section_id = sections.section_id
    LEFT JOIN section_teacher_aff ON sections.section_id = section_teacher_aff.section_id
    LEFT JOIN users ON section_teacher_aff.user_id = users.user_id
    LEFT JOIN courses ON section_student_aff.course_id = courses.course_id
    LEFT JOIN sites ON student_set.site_id = sites.site_id
  WHERE
    (
      (sites.site_name = 'Everest Public High School' AND courses.short_name LIKE 'Community Group')
      OR (sites.site_name = 'Summit Preparatory Charter High School' AND courses.short_name LIKE 'HCC')
      OR (sites.site_name IN ('Summit Public School: Denali', 'Summit Public School: K2',
                              'Summit Public School: Sierra')
                              AND courses.short_name LIKE 'Mentor PLT')
      OR (sites.site_name IN ('Summit Public School: Tamalpais',
                              'Summit Public School: Rainier',
                              'Summit Public School: Tahoma',
                              'Summit Public School: Shasta',
                              'Summit Public School: Atlas',
                              'Summit Public School: Olympus')
          AND courses.short_name LIKE 'Mentor Time')
    )
    AND DATE 'today' BETWEEN section_teacher_aff.start_date AND section_teacher_aff.end_date
    AND section_teacher_aff.primary_teacher IS TRUE
    AND (section_student_aff.leave_date > DATE 'today' OR section_student_aff.leave_date IS NULL)
)

SELECT DISTINCT
  students.local_student_id AS student_id
  , student_set.academic_year
  , student_set.grade_level
  , students.birth_date
  ,
  (
    COALESCE(
        codes.english_proficiency.code_translation
        , programs.code_translation
    )
  )AS english_proficiency
  , CASE WHEN students.reported_gender NOTNULL THEN students.reported_gender
      ELSE students.gender END AS reported_gender_calc
  , students.gender
  , race_ethnicity_combined.combined_race_ethnicity
  , student_common_demographics.sed AS is_sed
  , student_common_demographics.is_specialed
  , student_mentors.user_id AS mentor_teacher_id
  , student_mentors.last_name AS mentor_teacher_last_name
  , student_mentors.first_name AS mentor_teacher_first_name
  , student_mentors.email AS mentor_teacher_email
  , NOW()::DATE AS as_of
FROM
  student_set

  LEFT JOIN students on student_set.student_id = students.student_id
  LEFT JOIN student_house_aff ON students.student_id = student_house_aff.student_id
  LEFT JOIN houses ON student_house_aff.house_id = houses.house_id
  LEFT JOIN race_ethnicity_combined ON student_set.student_id = race_ethnicity_combined.student_id
  LEFT JOIN student_common_demographics ON
    student_set.student_id = student_common_demographics.student_id
  LEFT JOIN student_mentors ON student_set.student_id = student_mentors.student_id
  -- CA English Proficiency
  LEFT JOIN codes.english_proficiency
    ON codes.english_proficiency.code_id = students.english_proficiency
  -- WA English Proficiency
  LEFT JOIN codes.student_programs AS programs
    ON programs.code_id = student_common_demographics.ell_program_id;