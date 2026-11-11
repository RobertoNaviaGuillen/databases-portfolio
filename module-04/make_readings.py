"""Write module-04/readings.csv: 1,000 test readings for ingest.py.

Run from the repo root:  uv run python module-04/make_readings.py
500 timestamps (one per second) x 2 sensors (1 = temp_c, 2 = vib_rms). Seed 42, so the file is always the same.
"""
import csv, random
from datetime import datetime, timedelta
from pathlib import Path

random.seed(42)
start = datetime(2026, 3, 2, 8, 0, 0)
out = Path(__file__).with_name("readings.csv")

with out.open("w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["sensor_id", "ts", "value", "interval_s"])
    for i in range(500):
        ts = (start + timedelta(seconds=i)).strftime("%Y-%m-%d %H:%M:%S")
        w.writerow([1, ts, round(random.uniform(35, 60), 2), 1])     # temperature in degC
        w.writerow([2, ts, round(random.uniform(0.5, 1.9), 3), 1])   # vibration in mm/s, below the alarm limit
print(f"wrote {out.name}: 1000 rows")
