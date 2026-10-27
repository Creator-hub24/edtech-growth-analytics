-- =====================================================================
-- funnel_conversion.sql  (SQLite) — REAL OULAD data
-- Funnel: Registration -> First VLE activity -> First assessment submitted -> Pass/Distinction
-- Table: students (data/student_journey.csv, one row per student x module presentation)
-- =====================================================================

-- name: overall_funnel
WITH stages AS (
    SELECT 1 AS step, 'Registered' AS stage, COUNT(*) AS n FROM students
    UNION ALL SELECT 2, 'First VLE activity', SUM(has_vle_activity) FROM students
    UNION ALL SELECT 3, 'First assessment submitted', SUM(submitted_assessment) FROM students
    UNION ALL SELECT 4, 'Passed (Pass/Distinction)', SUM(passed) FROM students
)
SELECT step, stage, n AS students,
       ROUND(100.0 * n / FIRST_VALUE(n) OVER (ORDER BY step), 1) AS pct_of_registered,
       ROUND(100.0 * n / LAG(n) OVER (ORDER BY step), 1)         AS step_conversion_pct,
       LAG(n) OVER (ORDER BY step) - n                           AS students_lost
FROM stages ORDER BY step;

-- name: biggest_leak
WITH stages AS (
    SELECT 1 AS step, 'Registered' AS stage, COUNT(*) AS n FROM students
    UNION ALL SELECT 2, 'First VLE activity', SUM(has_vle_activity) FROM students
    UNION ALL SELECT 3, 'First assessment submitted', SUM(submitted_assessment) FROM students
    UNION ALL SELECT 4, 'Passed (Pass/Distinction)', SUM(passed) FROM students
), t AS (
    SELECT LAG(stage) OVER (ORDER BY step) || ' -> ' || stage AS transition,
           LAG(n) OVER (ORDER BY step) - n AS lost,
           ROUND(100.0 * (1 - 1.0 * n / LAG(n) OVER (ORDER BY step)), 1) AS drop_pct
    FROM stages
)
SELECT transition, lost, drop_pct, RANK() OVER (ORDER BY lost DESC) AS leak_rank
FROM t WHERE transition IS NOT NULL ORDER BY leak_rank;

-- name: final_result_mix
SELECT final_result, COUNT(*) AS students,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM students GROUP BY final_result ORDER BY students DESC;

-- name: submitted_but_not_passed
-- Of students who submitted at least one assessment, what happened?
SELECT final_result, COUNT(*) AS students,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_submitters
FROM students WHERE submitted_assessment = 1 GROUP BY final_result ORDER BY students DESC;

-- name: funnel_by_module
WITH m AS (
    SELECT code_module, COUNT(*) AS reg, SUM(has_vle_activity) AS vle,
           SUM(submitted_assessment) AS sub, SUM(passed) AS pass, SUM(withdrawn) AS wd
    FROM students GROUP BY code_module
)
SELECT code_module, reg AS registered,
       ROUND(100.0 * sub / reg, 1)  AS reg_to_submit_pct,
       ROUND(100.0 * pass / sub, 1) AS submit_to_pass_pct,
       ROUND(100.0 * pass / reg, 1) AS pass_rate_pct,
       ROUND(100.0 * wd / reg, 1)   AS withdrawal_pct,
       RANK() OVER (ORDER BY 1.0 * pass / reg DESC) AS pass_rank
FROM m ORDER BY pass_rank;

-- name: segment_conversion
-- "Channels" are replaced by real learner segments. One UNION per dimension.
WITH seg AS (
    SELECT 'imd_band' AS dimension, COALESCE(imd_band, 'Unknown') AS segment, passed, withdrawn, submitted_assessment FROM students
    UNION ALL SELECT 'age_band', age_band, passed, withdrawn, submitted_assessment FROM students
    UNION ALL SELECT 'highest_education', highest_education, passed, withdrawn, submitted_assessment FROM students
    UNION ALL SELECT 'prev_attempts', CASE WHEN num_of_prev_attempts >= 2 THEN '2+' ELSE CAST(num_of_prev_attempts AS TEXT) END, passed, withdrawn, submitted_assessment FROM students
    UNION ALL SELECT 'region', region, passed, withdrawn, submitted_assessment FROM students
), a AS (
    SELECT dimension, segment, COUNT(*) AS students,
           ROUND(100.0 * AVG(submitted_assessment), 1) AS submit_pct,
           ROUND(100.0 * AVG(passed), 1) AS pass_pct,
           ROUND(100.0 * AVG(withdrawn), 1) AS withdrawal_pct
    FROM seg GROUP BY dimension, segment
)
SELECT *, RANK() OVER (PARTITION BY dimension ORDER BY pass_pct DESC) AS rank_in_dimension,
       ROUND(pass_pct - AVG(pass_pct) OVER (PARTITION BY dimension), 1) AS pts_vs_dimension_avg
FROM a WHERE students >= 100
ORDER BY dimension, rank_in_dimension;

-- name: registration_timing
-- Does registering early (days before start) relate to outcomes?
WITH b AS (
    SELECT CASE WHEN date_registration IS NULL THEN 'unknown'
                WHEN date_registration < -90 THEN 'a) >90 days early'
                WHEN date_registration < -30 THEN 'b) 31-90 days early'
                WHEN date_registration < 0 THEN 'c) 1-30 days early'
                ELSE 'd) on/after start' END AS reg_timing, passed, withdrawn
    FROM students
)
SELECT reg_timing, COUNT(*) AS students, ROUND(100.0 * AVG(passed), 1) AS pass_pct,
       ROUND(100.0 * AVG(withdrawn), 1) AS withdrawal_pct
FROM b GROUP BY reg_timing ORDER BY reg_timing;
