-- =====================================================================
-- cohort_retention.sql  (SQLite) — REAL OULAD data
-- Cohorts = presentations 2013B, 2013J, 2014B, 2014J (B = February start, J = October start).
-- "Retained at day N" = not unregistered on or before day N (date_unregistration relative to start).
-- Students who unregistered before day 0 count as lost at day 0.
-- NOTE: 84 'Withdrawn' rows lack date_unregistration; they are treated as retained (data gap).
-- =====================================================================

-- name: retention_by_presentation
SELECT code_presentation, start_month, COUNT(*) AS registered,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 0), 1)   AS d0_pct,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 30), 1)  AS d30_pct,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 60), 1)  AS d60_pct,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 90), 1)  AS d90_pct,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 180), 1) AS d180_pct,
       ROUND(100.0 * AVG(passed), 1) AS pass_pct
FROM students GROUP BY code_presentation ORDER BY code_presentation;

-- name: feb_vs_oct_start
SELECT start_month, COUNT(*) AS registered,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 30), 1)  AS d30_pct,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 90), 1)  AS d90_pct,
       ROUND(100.0 * AVG(COALESCE(date_unregistration, 1e9) > 180), 1) AS d180_pct,
       ROUND(100.0 * AVG(withdrawn), 1) AS withdrawal_pct
FROM students GROUP BY start_month;

-- name: retention_curve_by_presentation
-- Survival curve in 15-day steps from day -30 to day 270, per presentation.
WITH RECURSIVE days(d) AS (SELECT -30 UNION ALL SELECT d + 15 FROM days WHERE d < 270)
SELECT s.code_presentation, days.d AS day_since_start,
       ROUND(100.0 * AVG(COALESCE(s.date_unregistration, 1e9) > days.d), 1) AS retained_pct
FROM students s CROSS JOIN days
GROUP BY s.code_presentation, days.d ORDER BY s.code_presentation, days.d;

-- name: withdrawal_timing
-- When do withdrawals happen? Share of all withdrawals by window + cumulative share.
WITH w AS (
    SELECT CASE WHEN date_unregistration < 0 THEN 'a) before start'
                WHEN date_unregistration <= 30 THEN 'b) day 0-30'
                WHEN date_unregistration <= 90 THEN 'c) day 31-90'
                WHEN date_unregistration <= 180 THEN 'd) day 91-180'
                ELSE 'e) day 181+' END AS window
    FROM students WHERE date_unregistration IS NOT NULL
)
SELECT window, COUNT(*) AS withdrawals,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct,
       ROUND(100.0 * SUM(COUNT(*)) OVER (ORDER BY window) / SUM(COUNT(*)) OVER (), 1) AS cumulative_pct
FROM w GROUP BY window ORDER BY window;

-- name: magic_moment_active_days_first_14
-- Early engagement: distinct active VLE days in days 0-13, among students still registered at day 14.
WITH b AS (
    SELECT MIN(active_days_d0_13, 10) AS active_days_14, passed, withdrawn
    FROM students WHERE COALESCE(date_unregistration, 1e9) > 14
), a AS (
    SELECT active_days_14, COUNT(*) AS students,
           ROUND(100.0 * AVG(passed), 1) AS pass_pct, ROUND(100.0 * AVG(withdrawn), 1) AS withdrawal_pct
    FROM b GROUP BY active_days_14
)
SELECT active_days_14 || CASE WHEN active_days_14 = 10 THEN '+' ELSE '' END AS active_days_first_14,
       students, pass_pct, withdrawal_pct,
       ROUND(pass_pct - LAG(pass_pct) OVER (ORDER BY active_days_14), 1) AS pass_jump_pts
FROM a ORDER BY active_days_14;

-- name: magic_moment_clicks_first_28_quintiles
-- Clicks in days 0-27, NTILE(5) quintiles, among students still registered at day 28.
WITH b AS (
    SELECT clicks_d0_27, passed, withdrawn,
           NTILE(5) OVER (ORDER BY clicks_d0_27) AS quintile
    FROM students WHERE COALESCE(date_unregistration, 1e9) > 28
)
SELECT quintile, COUNT(*) AS students, MIN(clicks_d0_27) AS min_clicks, MAX(clicks_d0_27) AS max_clicks,
       ROUND(100.0 * AVG(passed), 1) AS pass_pct, ROUND(100.0 * AVG(withdrawn), 1) AS withdrawal_pct
FROM b GROUP BY quintile ORDER BY quintile;

-- name: first_assessment_score_vs_outcome
WITH b AS (
    SELECT CASE WHEN first_assessment_score IS NULL THEN 'no score'
                WHEN first_assessment_score < 40 THEN 'a) <40'
                WHEN first_assessment_score < 60 THEN 'b) 40-59'
                WHEN first_assessment_score < 80 THEN 'c) 60-79'
                ELSE 'd) 80+' END AS first_score, passed, withdrawn
    FROM students WHERE submitted_assessment = 1
)
SELECT first_score, COUNT(*) AS students, ROUND(100.0 * AVG(passed), 1) AS pass_pct,
       ROUND(100.0 * AVG(withdrawn), 1) AS withdrawal_pct
FROM b GROUP BY first_score ORDER BY first_score;
