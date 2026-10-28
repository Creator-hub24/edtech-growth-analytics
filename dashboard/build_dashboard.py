"""Build docs/index.html: a self-contained, mobile-first dashboard (Plotly.js via CDN)
from the repo's real derived OULAD data, using the same SQL as sql/*.sql.

Usage: python dashboard/build_dashboard.py
"""
import json, sqlite3, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sql"))
import run_queries as rq  # noqa: E402


def rec(df):
    return json.loads(df.to_json(orient="records"))


def main():
    conn = sqlite3.connect(":memory:"); rq.load(conn)
    Q = rq.run_all(conn, quiet=True)
    f = Q["overall_funnel"]
    import pandas as pd
    s = pd.read_sql_query("SELECT COUNT(*) n, SUM(withdrawn) w, AVG(COALESCE(date_unregistration,1e9)>90) d90 FROM students", conn).iloc[0]
    seg = Q["segment_conversion"]
    data = {
        "kpi": {"registered": int(f.students[0]), "vle": int(f.students[1]), "submitted": int(f.students[2]),
                "passed": int(f.students[3]), "withdrew": int(s.w), "d90": float(s.d90)},
        "funnel": rec(f), "leak": rec(Q["biggest_leak"]),
        "wtiming": rec(Q["withdrawal_timing"]),
        "curves": rec(Q["retention_curve_by_presentation"]),
        "retention": rec(Q["retention_by_presentation"]),
        "magic": rec(Q["magic_moment_active_days_first_14"]),
        "score": rec(Q["first_assessment_score_vs_outcome"][lambda d: d.first_score != "no score"]),
        "segments": {d: rec(seg[seg.dimension == d].sort_values("segment")) for d in
                     ["imd_band", "highest_education", "age_band", "prev_attempts", "region"]},
        "modules": rec(Q["funnel_by_module"]),
        "hyp": rec(Q["hypothetical_ltv_cac_by_imd_band"].sort_values("imd_band")),
    }
    html = (Path(__file__).parent / "template.html").read_text().replace("/*__DATA__*/null", json.dumps(data, separators=(",", ":")))
    out = ROOT / "docs" / "index.html"; out.parent.mkdir(exist_ok=True); out.write_text(html)
    (ROOT / "docs" / ".nojekyll").write_text("")
    print(f"Wrote {out} ({out.stat().st_size/1024:.0f} KB)")


if __name__ == "__main__":
    main()
