"""Aggregate raw OULAD tables into one row per student-module-presentation enrolment.

Output: data/student_journey.csv (committed, ~32.6k rows) and data/vle_weekly.csv
(weekly clicks by presentation and final result, for curves). All day offsets are
relative to the module presentation start (day 0), as in OULAD.
"""
import pandas as pd, numpy as np
from pathlib import Path

D = Path(__file__).resolve().parent; RAW = D / "raw"
KEY = ["code_module", "code_presentation", "id_student"]

info = pd.read_csv(RAW / "studentInfo.csv").replace("?", np.nan)
reg = pd.read_csv(RAW / "studentRegistration.csv").replace("?", np.nan)
courses = pd.read_csv(RAW / "courses.csv")
asm = pd.read_csv(RAW / "assessments.csv").replace("?", np.nan)
sa = pd.read_csv(RAW / "studentAssessment.csv").replace("?", np.nan)

vle = pd.read_csv(RAW / "studentVle.csv", usecols=KEY + ["date", "sum_click"],
                  dtype={"code_module": "category", "code_presentation": "category",
                         "id_student": "int32", "date": "int16", "sum_click": "int32"})
daily = vle.groupby(KEY + ["date"], observed=True).sum_click.sum().reset_index()
del vle

def window(lo, hi, tag):
    w = daily[(daily.date >= lo) & (daily.date <= hi)].groupby(KEY, observed=True)
    return pd.DataFrame({f"clicks_{tag}": w.sum_click.sum(), f"active_days_{tag}": w.date.nunique()})

g = daily.groupby(KEY, observed=True)
feat = pd.DataFrame({"first_vle_day": g.date.min(), "last_vle_day": g.date.max(),
                     "total_clicks": g.sum_click.sum(), "total_active_days": g.date.nunique()})
feat = feat.join(window(-30, -1, "prestart")).join(window(0, 13, "d0_13")).join(window(0, 27, "d0_27"))
feat = feat.reset_index()
for k in feat.columns: 
    if hasattr(feat[k], "cat"): feat[k] = feat[k].astype(str)

sa = sa.merge(asm[["id_assessment", "code_module", "code_presentation", "assessment_type", "date"]], on="id_assessment")
sa["score"] = pd.to_numeric(sa.score, errors="coerce")
sub = sa.groupby(KEY).agg(first_submission_day=("date_submitted", "min"), n_assessments_submitted=("id_assessment", "count"),
                          mean_score=("score", "mean")).reset_index()
first_tma = sa.sort_values("date_submitted").groupby(KEY).first()[["score"]].rename(columns={"score": "first_assessment_score"}).reset_index()

df = (info.merge(reg, on=KEY, how="left").merge(courses, on=["code_module", "code_presentation"], how="left")
          .merge(feat, on=KEY, how="left").merge(sub, on=KEY, how="left").merge(first_tma, on=KEY, how="left"))
for c in ["date_registration", "date_unregistration"]: df[c] = pd.to_numeric(df[c])
fill0 = [c for c in df.columns if c.startswith(("clicks_", "active_days_", "total_"))] + ["n_assessments_submitted"]
df[fill0] = df[fill0].fillna(0).astype(int)
df["start_month"] = np.where(df.code_presentation.str.endswith("B"), "February", "October")
df["has_vle_activity"] = (df.first_vle_day.notna()).astype(int)
df["submitted_assessment"] = (df.n_assessments_submitted > 0).astype(int)
df["passed"] = df.final_result.isin(["Pass", "Distinction"]).astype(int)
df["withdrawn"] = (df.final_result == "Withdrawn").astype(int)
df.to_csv(D / "student_journey.csv", index=False)

daily = daily.merge(info[KEY + ["final_result"]].astype({"code_module": "category", "code_presentation": "category"}), on=KEY)
daily["week"] = daily.date // 7
wk = daily.groupby(["code_presentation", "final_result", "week"], observed=True).agg(clicks=("sum_click", "sum"), students=("id_student", "nunique")).reset_index()
wk.to_csv(D / "vle_weekly.csv", index=False)
print(f"student_journey.csv: {len(df):,} rows; vle_weekly.csv: {len(wk):,} rows")
