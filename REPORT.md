# Executive Growth Summary — Open University Learning Analytics Dataset (OULAD)

> **Real data.** Kuzilek J., Hlosta M., Zdrahal Z. (2017). *Open University Learning Analytics dataset.* Scientific Data 4, 170171. https://doi.org/10.1038/sdata.2017.171 — CC BY 4.0.
> 32,593 student × module enrolments, 7 modules, 4 presentations (2013B, 2013J, 2014B, 2014J; B = February start, J = October start). UK distance learning: adult learners, not Indian school students.
> Sections 1–4 are **real findings**. Section 5 is a **hypothetical** money layer. Section 6 turns the findings into experiments for an EdTech like Edumaths360.
> Every number reproduces from `python sql/run_queries.py`.

## TL;DR (real data)

| Metric | Value |
|---|---|
| Enrolments | **32,593** |
| Pass rate (Pass + Distinction) | **47.2%** |
| Withdrawal rate ("churn") | **31.2%** |
| Still registered at day 90 | **78.4%** |
| Biggest leak | **First assessment submitted → Passed: 40.5% lost** (10,458 learners) |
| When churn happens | **26.6% of withdrawals before day 0, 50.9% by day 30** |
| Strongest early signals | Active VLE days in days 0–13 (27.7% → 74.6% pass), **first assessment score ≥ 60** (33% → 57% pass) |

## 1. Funnel: where is the biggest leak?

| Stage | Learners | % of registered | Step conversion |
|---|---:|---:|---:|
| Registered | 32,593 | 100% | – |
| First VLE activity | 29,228 | 89.7% | 89.7% |
| First assessment submitted | 25,843 | 79.3% | 88.4% |
| Passed (Pass/Distinction) | 15,385 | 47.2% | **59.5%** |

- **Activation is not the main problem here.** About 90% of learners use the VLE and 79% submit an assessment. The leak is **after the first submission**: 22.3% of submitters go on to fail and 18.2% withdraw.
- Modules differ widely: **AAA passes 71.0%** with 16.8% withdrawal, while **CCC passes 37.8%** with 44.5% withdrawal.
- Registering very early (>90 days before start) goes with the *highest* withdrawal (38.3%), compared with 25.6% for those registering 1–30 days before. Early sign-ups decay before the course even begins.

## 2. Cohort retention (presentations)

| Presentation | Registered | D0 | D30 | D60 | D90 | D180 | Pass % |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2013B (Feb) | 4,684 | 93.9 | 87.8 | 83.8 | 80.8 | 73.9 | 44.7 |
| 2013J (Oct) | 8,845 | 89.3 | 86.5 | 84.0 | **82.2** | **75.4** | **50.6** |
| 2014B (Feb) | 7,804 | 87.5 | 83.3 | 79.3 | 76.6 | 69.6 | 43.0 |
| 2014J (Oct) | 11,260 | 92.0 | **81.7** | 78.3 | 75.8 | 68.6 | 48.5 |

- **February vs October starts barely differ** (D90 78.1% vs 78.6%; D180 71.2% vs 71.5%). Unlike the simulated repo, the data shows **no seasonal-cohort effect**. The variation is by year and module mix: 2014 presentations retain about 5 points worse than 2013.
- 2014J lost **9 points between day 0 and day 15** (92.0% → 83.1%), the steepest early drop of any cohort.
- **Withdrawal timing:** 26.6% before start, 24.3% in days 0–30, 18.9% in days 31–90, 22.7% in days 91–180 and 7.5% after. Half of all churn happens by day 30.

## 3. Is there a "magic moment"? (what the data actually shows)

**Active VLE days in days 0–13**, among learners still registered at day 14:

| Active days | 0 | 1 | 2 | 3 | 5 | 7 | 10+ |
|---|---:|---:|---:|---:|---:|---:|---:|
| Pass % | 27.7 | 39.9 | 45.0 | 52.2 | 57.5 | 62.6 | 74.6 |
| Withdrawal % | 28.1 | 23.8 | 22.1 | 21.1 | 20.2 | 19.5 | 13.6 |

- **There is no single sharp threshold.** Outcomes improve steadily with every extra active day (dose-response). The largest single step is **0 → 1 active day (+12.2 pts)**, followed by 2 → 3 days (+7.2 pts). A sensible product target is **"3 active days in the first 2 weeks"**: it is the point where pass rate first exceeds 50%.
- **Clicks in days 0–27, by quintile:** the bottom 20% (≤48 clicks) pass at 35.4%, the top 20% (≥433) at 73.6%.
- **The first assessment score is the sharpest threshold in the dataset.** Learners scoring 40–59 pass at 33.3%; those scoring 60–79 pass at 56.5% (+23 pts), and those scoring 80+ at 72.9%. Learners scoring under 40 withdraw at 39.3%.
- In the weekly click curves, eventual Withdrawn and Fail learners are already well below passers in week 0. The gap is visible before any assessment.
- *Caveat:* these are correlations. Motivated learners both click more and pass more, so only an experiment can show cause.

## 4. Segments (in place of marketing channels)

| Dimension | Best → worst pass rate |
|---|---|
| IMD band (deprivation) | 90–100% (least deprived): **57.5%** → 0–10%: **35.2%** |
| Highest education | Post-grad 65.5% → No formal quals 29.7% |
| Previous attempts | 0: 49.3% → 1: 34.6% → 2+: **27.5%** |
| Age | 55+: 61.6% → 35–55: 52.2% → 0–35: 45.0% |
| Region | Ireland 54.9% → North Western 40.2% |

Repeat-attempt learners and learners from more deprived areas are the clearest at-risk segments.

## 5. ⚠️ Hypothetical unit economics (NOT real data)

OULAD has **no prices, revenue or marketing spend.** `assumptions/unit_economics_assumptions.csv` sets a ₹2,500 fee per module, full refund for withdrawals by day 14, 70% margin, 45% / 10% re-enrolment for passers / non-passers and a **flat** ₹750 CAC. Only the pass and withdrawal behaviour comes from the data. On those assumptions, LTV:CAC runs from **2.46x (IMD 0–10%) to 2.99x (IMD 90–100%)**. That gap comes entirely from real differences in pass and withdrawal rates. Edit the CSV to run your own scenarios (`sql/unit_economics_hypothetical.sql`).

## 6. Growth experiments for an EdTech like Edumaths360 (Class 6–10 maths)

These carry the OULAD patterns over to a different context (Indian school students, not UK adults), so each one needs its own test.

| # | Experiment | Based on (real finding) | Hypothesis | Primary metric | Expected impact (hypothesis) |
|---|---|---|---|---|---|
| **1** | **"3 days in the first 14" onboarding streak**: daily 10-minute practice sets, WhatsApp nudges to student and parent on days 1, 3 and 7 | Pass rate climbs from 27.7% at 0 days to 52.2% at 3 days; biggest jump 0 → 1 | Getting each learner to 3 active days early cuts churn | % reaching 3 active days by day 14; 30-day retention | +5–10 pts in learners reaching 3 days |
| **2** | **First-test "early win" + remediation**: a calibrated first mock test, and any score below 60 triggers a free doubt session or revision pack | First score ≥ 60 → pass 56.5% vs 33.3%; score < 40 → 39% withdraw | Lifting first scores (or catching low scorers) reduces failure and drop-out | Share scoring ≥ 60 on the first test; next-test attempt rate | Fewer early withdrawals among low scorers |
| **3** | **Pre-start engagement for early sign-ups**: a "warm-up week" of content before the batch starts | Learners registering >90 days early withdraw at 38.3% vs 25.6%; 26.6% of churn is before day 0 | Keeping early sign-ups busy before the start prevents pre-start churn | Withdrawal before day 0 | −20% pre-start withdrawals |
| 4 | **At-risk segment playbook**: repeat-attempt students and lower-income areas get mentor check-ins and EMI or scholarship pricing | 2+ prior attempts pass at 27.5%; IMD 0–10% at 35.2% | Targeted support closes part of the gap | Pass/retention gap vs average | Close the gap by a third |
| 5 | **Week-0 risk score**: flag learners with 0 active days at day 7 or bottom-quintile clicks at day 28 for outreach | Withdrawn learners lag passers from week 0 | Early outreach to flagged learners lifts retention | D60 retention, flagged vs control | Measure lift through an A/B holdout |

**Run order:** 1 and 2 first (cheap product changes aimed at the strongest signals), then 3. Run 4 and 5 once there is enough data to build the risk flags.

## Methodology notes
- Funnel stages use `studentVle` (any click, including before the start), `studentAssessment` (any submission, including exams) and `final_result`.
- Retention at day N means `date_unregistration` is null or later than N. **84 learners marked Withdrawn have no unregistration date** and are counted as retained, which overstates retention by about 0.3 pts.
- Magic-moment tables only include learners still registered at the end of the window (day 14 or 28), to avoid survivorship leaking into the feature.
