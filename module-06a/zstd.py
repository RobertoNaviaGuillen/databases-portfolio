# module-06a/zstd.py: run with  uv run python module-06a/zstd.py
"""Section 7 core homework: write a zstd-compressed copy and compare size and dashboard time."""
import statistics
import time
from pathlib import Path

import duckdb

here = Path(__file__).parent
snappy = here / "report_history.parquet"
zstd = here / "report_zstd.parquet"
RUNS = 5

con = duckdb.connect()
con.execute(f"COPY (SELECT * FROM read_parquet('{snappy}')) TO '{zstd}' (FORMAT parquet, COMPRESSION zstd)")

DASHBOARD = """SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM read_parquet('{f}') WHERE done_on >= '2026-01-01'
GROUP BY machine_id, site, technician ORDER BY machine_id, site, technician"""

same = con.execute(DASHBOARD.format(f=snappy)).fetchall() == con.execute(DASHBOARD.format(f=zstd)).fetchall()
print("identical results:", same)
times = {"snappy": [], "zstd": []}
for _ in range(RUNS):                       # interleaved, after the warm-up above
    for name, f in (("snappy", snappy), ("zstd", zstd)):
        t0 = time.perf_counter()
        con.execute(DASHBOARD.format(f=f)).fetchall()
        times[name].append((time.perf_counter() - t0) * 1000)
for name, f in (("snappy", snappy), ("zstd", zstd)):
    print(f"{name:7s} {f.stat().st_size / 1e6:5.2f} MB   dashboard median {statistics.median(times[name]):5.1f} ms")
