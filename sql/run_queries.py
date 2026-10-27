"""Load derived OULAD CSVs (+ the separate assumptions file) into SQLite and run every named query.

Usage: python sql/run_queries.py [--quiet]
"""
import re, sqlite3, sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "oulad.db"


def load(conn):
    pd.read_csv(ROOT / "data/student_journey.csv").to_sql("students", conn, if_exists="replace", index=False)
    pd.read_csv(ROOT / "assumptions/unit_economics_assumptions.csv").to_sql("assumptions", conn, if_exists="replace", index=False)


def named_queries(path):
    for block in re.split(r"^-- name:\s*", path.read_text(), flags=re.M)[1:]:
        name, body = block.split("\n", 1)
        yield name.strip(), body.strip().rstrip(";")


def run_all(conn, quiet=False):
    out = {}
    for f in sorted((ROOT / "sql").glob("*.sql")):
        for name, q in named_queries(f):
            out[name] = df = pd.read_sql_query(q, conn)
            if not quiet:
                print(f"\n=== {f.name} :: {name} ({len(df)} rows) ===")
                print(df.to_string(index=False, max_rows=40))
    return out


if __name__ == "__main__":
    conn = sqlite3.connect(DB); load(conn)
    res = run_all(conn, quiet="--quiet" in sys.argv)
    print(f"\nOK: {len(res)} queries executed successfully against {DB.name}")
