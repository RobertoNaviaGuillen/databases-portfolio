# module-06a/race.py: run with  uv run python module-06a/race.py
"""Same two queries, two engines, interleaved, median of RUNS runs.

Change from the workbook: strftime takes its arguments in a different order in the two engines.
SQLite: strftime(format, date). DuckDB: strftime(date, format). The workbook's
strftime(done_on, '%Y-%m') returns NULL in SQLite, so SQLite grouped all 2M rows into 50 groups
with an empty month while DuckDB returned 1,500. The monthly query below uses each engine's own
order, and every query is checked for identical results before it is timed.
"""
import sqlite3
import statistics
import time
from pathlib import Path

import duckdb

RUNS = 5        # odd on purpose: the median is then a real run. Try 3, 7, 9.

here = Path(__file__).parent
sq = sqlite3.connect(here / "history.db")
duck = duckdb.connect()
pq = str(here / "report_history.parquet")

DASHBOARD = """SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM {src} WHERE done_on >= '2026-01-01'
GROUP BY machine_id, site, technician ORDER BY machine_id, site, technician"""

MONTHLY = """SELECT {month} AS month, machine_id,
       COUNT(*) AS jobs, SUM(part_price) AS cost
FROM {src} GROUP BY month, machine_id ORDER BY month, machine_id"""

QUERIES = {
    "dashboard": (DASHBOARD.format(src="report_history"),
                  DASHBOARD.format(src=f"read_parquet('{pq}')")),
    "monthly": (MONTHLY.format(month="strftime('%Y-%m', done_on)", src="report_history"),
                MONTHLY.format(month="strftime(done_on, '%Y-%m')", src=f"read_parquet('{pq}')")),
}


def timed_ms(fn):
    t0 = time.perf_counter()
    fn()
    return (time.perf_counter() - t0) * 1000


def spread(times):
    return f"{min(times):.1f}-{max(times):.1f}"


for name, (sqlite_sql, duckdb_sql) in QUERIES.items():
    run_sqlite = lambda: sq.execute(sqlite_sql).fetchall()
    run_duckdb = lambda: duck.execute(duckdb_sql).fetchall()

    a, b = run_sqlite(), run_duckdb()   # warm-up: load the pages, discard the timing
    same = [tuple(r) for r in a] == [tuple(r) for r in b]
    print(f"{name:10s} rows sqlite {len(a)}, duckdb {len(b)}, identical results: {same}")

    sqlite_times, duckdb_times = [], []
    for _ in range(RUNS):  # interleaved: alternate the engines
        sqlite_times.append(timed_ms(run_sqlite))
        duckdb_times.append(timed_ms(run_duckdb))

    s = statistics.median(sqlite_times)
    d = statistics.median(duckdb_times)
    print(f"{name:10s} sqlite {s:7.1f} ms [{spread(sqlite_times)}]"
          f"   duckdb {d:6.1f} ms [{spread(duckdb_times)}]   {s / d:6.1f}x")
