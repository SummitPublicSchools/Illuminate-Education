/*

Summary
• Pulls a list of currently enrolled students, demographic factors, and Fall 2016-2017 NWEA MAP data

Level of Detail
• Student > NWEA MAP Discipline

*/


SELECT DISTINCT

  -- Student Demographic Information
    TRIM(sites.site_name) AS "Site"
  , grade_levels.short_name::INTEGER AS "Grade Level"
  , students.local_student_id AS "Student ID"
  , students.student_id AS "Illuminate Student ID"
  , students.state_student_id AS "State Student ID"
  , TRIM(students.last_name) AS "Student Last Name"
  , TRIM(students.first_name) AS "Student First Name"
  , TRIM(students.middle_name) AS "Student Middle Name"
  , LOWER(students.email) AS "Student Email"
  , users.last_name AS "Mentor Last Name"
  , users.first_name AS "Mentor First Name"
  , LOWER(users.email1) AS "Mentor Email"
  , students.school_enter_date AS "School Enter Date"
  , students.birth_date AS "Birth Date"
  , students.gender AS "Gender"
  , race_ethnicity.combined_race_ethnicity AS "Federal Reported Race"
  , students.is_hispanic AS "Hispanic / Latino Status"
  , (
      COALESCE
        (
          el.code_translation,  -- CA
          programs.code_translation  -- WA
        )
    ) AS "English Proficiency"
  , demographics.sed AS "SED Status"
  , demographics.is_specialed AS "SPED Status"

  -- NWEA MAP Data
  , nwea_2017.date_imported AS "NWEA MAP Data Date Imported"
  , nwea_2017."nwea_2017_TermName" AS "Term Name"
  , nwea_2017."nwea_2017_NormsReferenceData" AS "Norms Reference Data"
  , nwea_2017."nwea_2017_Discipline" AS "Discipline"
  , nwea_2017."nwea_2017_TestStartDate" AS "Test Start Date"
  , nwea_2017."nwea_2017_TestStartTime" AS "Test Start Time"
  , nwea_2017."nwea_2017_TestDurationMinutes" AS "Test Duration Minutes"
  , nwea_2017."nwea_2017_TestRITScore" AS "Test RIT Score"
  , nwea_2017."nwea_2017_TestStandardError" AS "Test Standard Error"
  , nwea_2017."nwea_2017_TestPercentile" AS "Test Percentile"
  , nwea_2017."nwea_2017_PercentCorrect" AS "Percent Correct"
  , nwea_2017."nwea_2017_RITtoReadingScore" AS "RIT to Reading Score"
  , nwea_2017."nwea_2017_RITtoReadingMin" AS "RIT to Reading Min"
  , nwea_2017."nwea_2017_RITtoReadingMax" AS "RIT to Reading Max"
  , nwea_2017."nwea_2017_ProjectedProficiencyStudy1" AS "Projected Proficiency Study 1"
  , nwea_2017."nwea_2017_ProjectedProficiencyLevel1" AS "Projected Proficiency Level 1"
  , nwea_2017."nwea_2017_ProjectedProficiencyStudy2" AS "Projected Proficiency Study 2"
  , nwea_2017."nwea_2017_ProjectedProficiencyLevel2" AS "Projected Proficiency Level 2"
  , nwea_2017."nwea_2017_ProjectedProficiencyStudy3" AS "Projected Proficiency Study 3"
  , nwea_2017."nwea_2017_ProjectedProficiencyLevel3" AS "Projected Proficiency Level 3"
  , nwea_2017."nwea_2017_ProjectedProficiencyStudy4" AS "Projected Proficiency Study 4"
  , nwea_2017."nwea_2017_ProjectedProficiencyLevel4" AS "Projected Proficiency Level 4"
  , nwea_2017."nwea_2017_FallToFallProjectedGrowth" AS "Fall to Fall Projected Growth"
  , nwea_2017."nwea_2017_FalltoFallObservedGrowth" AS "Fall to Fall Observed Growth"
  , nwea_2017."nwea_2017_FalltoFallObservedGrowthSE" AS "Fall to Fall Observed Growth SE"
  , nwea_2017."nwea_2017_FalltoFallMetProjectedGrowth" AS "Fall to Fall Met Projected Growth"
  , nwea_2017."nwea_2017_FalltoFallConditionalGrowthIndex" AS "Fall to Fall Conditional Growth Index"
  , nwea_2017."nwea_2017_FalltoFallConditionalGrowthPercentile" AS "Fall to Fall Conditional Growth Percentile"
  , nwea_2017."nwea_2017_TypicalFallToFallGrowth" AS "Typical Fall to Fall Growth"
  , nwea_2017."nwea_2017_TypicalFallToWinterGrowth" AS "Typical Fall to Winter Growth"
  , nwea_2017."nwea_2017_TypicalFallToSpringGrowth" AS "Typical Fall to Spring Growth"


FROM
  -- Start with ss_current to pull only currently enrolled students
  matviews.ss_current AS ss

  -- Join current students to students, grade levels, and sites
  INNER JOIN students
    USING (student_id)
  INNER JOIN grade_levels
    USING (grade_level_id)
  INNER JOIN sites
    ON sites.site_id = ss.site_id
    AND sites.exclude_from_current_sites IS FALSE   -- excludes SPS as a district
    AND sites.site_name <> 'SPS Tour'

  -- Join current students to counselors (mentors)
  LEFT OUTER JOIN student_counselor_aff AS counselors
    ON counselors.student_id = ss.student_id
    AND counselors.start_date <= CURRENT_DATE
    AND (counselors.end_date IS NULL OR counselors.end_date > CURRENT_DATE)
  LEFT OUTER JOIN users
    ON counselors.user_id = users.user_id

  -- Join current students to demographics
  LEFT OUTER JOIN race_ethnicity_combined AS race_ethnicity
    ON race_ethnicity.student_id = ss.student_id
  LEFT OUTER JOIN student_common_demographics AS demographics
    ON demographics.student_id = ss.student_id
  LEFT OUTER JOIN codes.english_proficiency AS el  -- CA
    ON el.code_id = students.english_proficiency
  LEFT OUTER JOIN codes.student_programs AS programs  -- WA
    ON programs.code_id = demographics.ell_program_id

  -- Join current students to NWEA MAP data
  LEFT OUTER JOIN national_assessments.nwea_2017 AS nwea_2017
    ON nwea_2017.student_id = ss.student_id
    -- GrowthMeasureYN:
    -- When more than one result record exists for a given student and test, only one record counts for growth reporting, marked TRUE.
    AND nwea_2017."nwea_2017_GrowthMeasureYN" = 'TRUE'


ORDER BY
    "Site"
  , "Grade Level"
  , "Student Last Name"
  , "Student First Name"
