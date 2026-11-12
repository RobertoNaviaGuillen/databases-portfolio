# module-06a/plan.py: run with  uv run python module-06a/plan.py
"""The DuckDB physical plan: rows and time per operator (this runs the query).
Also SELECT * for comparison, to see the projections change.
On Windows run with PYTHONIOENCODING=utf-8, because the plan is drawn with box characters."""
from pathlib import Path

import duckdb

here = Path(__file__).parent
pq = here / "report_history.parquet"

con = duckdb.connect()
for title, select in (("dashboard (4 of 7 columns)", "machine_id, site, technician, SUM(part_price) AS cost"),):
    plan = con.execute(f"""
        EXPLAIN ANALYZE
        SELECT {select}
        FROM read_parquet('{pq}')
        GROUP BY machine_id, site, technician
    """).fetchall()[0][1]
    print(f"== {title}")
    print(plan)

print("== SELECT * (all 7 columns)")
print(con.execute(f"EXPLAIN ANALYZE SELECT * FROM read_parquet('{pq}')").fetchall()[0][1])
