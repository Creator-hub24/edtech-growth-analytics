-- =====================================================================
-- unit_economics_hypothetical.sql  (SQLite)
-- !!! HYPOTHETICAL LAYER !!! OULAD contains NO price, revenue or marketing-spend data.
-- Real learner outcomes (passed / withdrawal day) x made-up assumptions from
-- assumptions/unit_economics_assumptions.csv. Change that file to run scenarios.
-- Do NOT read these outputs as findings about the Open University.
-- =====================================================================

-- name: hypothetical_ltv_cac_by_imd_band
WITH p AS (
    SELECT MAX(CASE WHEN parameter = 'fee_per_module' THEN value END) AS fee,
           MAX(CASE WHEN parameter = 'refund_window_days' THEN value END) AS refund_days,
           MAX(CASE WHEN parameter = 'gross_margin' THEN value END) AS margin,
           MAX(CASE WHEN parameter = 'reenrol_rate_if_passed' THEN value END) AS re_pass,
           MAX(CASE WHEN parameter = 'reenrol_rate_if_not_passed' THEN value END) AS re_fail
    FROM assumptions
), s AS (
    SELECT COALESCE(imd_band, 'Unknown') AS imd_band, COUNT(*) AS enrolments,
           AVG(COALESCE(date_unregistration, 1e9) > (SELECT refund_days FROM p)) AS paying_share,
           AVG(passed) AS pass_rate
    FROM students GROUP BY 1
), m AS (
    SELECT s.*, a.value AS cac,
           p.fee * s.paying_share * p.margin AS first_module_margin,
           -- expected future modules: geometric series of re-enrolment
           p.fee * s.paying_share * p.margin *
             (1.0 / (1 - (s.pass_rate * p.re_pass + (1 - s.pass_rate) * p.re_fail))) AS ltv
    FROM s JOIN p JOIN assumptions a ON a.parameter = 'cac' AND a.segment = s.imd_band
)
SELECT imd_band, enrolments, ROUND(100 * paying_share, 1) AS paying_after_refund_pct,
       ROUND(100 * pass_rate, 1) AS real_pass_pct, cac AS hyp_cac_inr, ROUND(ltv) AS hyp_ltv_inr,
       ROUND(ltv / cac, 2) AS hyp_ltv_to_cac,
       ROUND(cac / (first_module_margin / 9.0), 1) AS hyp_payback_months_9mo_module,
       RANK() OVER (ORDER BY ltv / cac DESC) AS rank
FROM m ORDER BY rank;
