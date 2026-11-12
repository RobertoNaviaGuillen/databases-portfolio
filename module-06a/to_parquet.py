# module-06a/to_parquet.py: run with  uv run python module-06a/to_parquet.py
"""200k CSV -> 2M-row Parquet. DuckDB does the expansion, no database server involved."""
import sqlite3
from pathlib import Path

import duckdb

here = Path(__file__).parent
csv_path = here / "report_jobpart.csv"
parquet = here / "report_history.parquet"
db = here / "history.db"

con = duckdb.connect()          # in-process, embedded: nothing to start
con.execute(f"""
    COPY (
      SELECT r.job_id + k * 1000000 AS job_id, r.machine_id, r.site,
             r.technician, r.part_no, r.part_price,
             CAST(r.done_on AS DATE) + CAST(k * 91 AS INTEGER) AS done_on
      FROM read_csv_auto('{csv_path}', header = true) r,
           range(0, 10) t(k)
    ) TO '{parquet}' (FORMAT parquet)
""")

print("parquet rows:", con.execute(
    f"SELECT COUNT(*) FROM read_parquet('{parquet}')").fetchone()[0])
print("parquet MB  :", round(parquet.stat().st_size / 1e6, 2))

# Check both sides agree before timing anything: rows, total price, date range.
CHECK = "SELECT COUNT(*), ROUND(SUM(part_price), 2), MIN(done_on), MAX(done_on) FROM {src}"
pq_check = con.execute(CHECK.format(src=f"read_parquet('{parquet}')")).fetchone()
sq_check = sqlite3.connect(db).execute(CHECK.format(src="report_history")).fetchone()
print("parquet check:", pq_check[0], pq_check[1], str(pq_check[2]), str(pq_check[3]))
print("sqlite check :", sq_check[0], sq_check[1], sq_check[2], sq_check[3])
same = (pq_check[0], pq_check[1], str(pq_check[2]), str(pq_check[3])) == sq_check
print("identical    :", same)
print("history.db MB:", round(db.stat().st_size / 1e6, 2))
