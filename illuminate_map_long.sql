/******************************************************************************
MAP Scores - Long Format
  This query includes map scores from SY18 and SY17 in a long format suitable
  for Tableau or a pivot table.
  There is a separate row per student, per year, per test subject, per test
  period.
  For example, if a student took all all possible MAP assessments in
  in SY18 and SY17 he/she would have 12 rows returned as part of this query.
******************************************************************************/


WITH map_sy18 AS (
 SELECT
   "nwea_2018_localStudentID" AS local_student_id
   , "nwea_2018_SchoolName" AS school
   , "nwea_2018_TermName" AS test_period
   , "nwea_2018_Discipline" AS test_subject
   , "nwea_2018_TestRITScore" AS test_score
   , "nwea_2018_TestPercentile" AS test_percentile
   , "nwea_2018_TypicalFallToWinterGrowth" AS typical_fall_winter_growth
   , "nwea_2018_TypicalFallToSpringGrowth" AS typical_fall_spring_growth
 FROM national_assessments.nwea_2018
 WHERE
   --Exclude scores that NWEA does count for growth purposes
   "nwea_2018_GrowthMeasureYN" = 'TRUE' 
), map_sy17 AS (
 SELECT
   "nwea_2017_localStudentID" AS local_student_id
   , "nwea_2017_SchoolName" AS school
   , "nwea_2017_TermName" AS test_period
   , "nwea_2017_Discipline" AS test_subject
   , "nwea_2017_TestRITScore" AS test_score
   , "nwea_2017_TestPercentile" AS test_percentile
   , "nwea_2017_TypicalFallToWinterGrowth" AS typical_fall_winter_growth
   , "nwea_2017_TypicalFallToSpringGrowth" AS typical_fall_spring_growth
 FROM national_assessments.nwea_2017
 WHERE
   --Exclude scores that NWEA does count for growth purposes
   "nwea_2017_GrowthMeasureYN" = 'TRUE' 
), map_all AS (
 SELECT
   local_student_id
   , school
   , test_period
   , test_subject
   , test_score
   , test_percentile
   , typical_fall_winter_growth
   , typical_fall_spring_growth
 FROM map_sy18
 
 UNION
 
 SELECT
   local_student_id
   , school
   , test_period
   , test_subject
   , test_score
   , test_percentile
   , typical_fall_winter_growth
   , typical_fall_spring_growth
 FROM map_sy17
)
SELECT
  local_student_id
  , school
  , test_period
  , test_subject
  , test_score
  , test_percentile
  , typical_fall_winter_growth
  , typical_fall_spring_growth
FROM map_all