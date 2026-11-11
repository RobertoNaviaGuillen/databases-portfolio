"""Task 3: what does the alarm trigger cost on the ingest path?

Run from the repo root:  uv run python module-04/trigger_bench.py
Each run builds a fresh in-memory copy of the edge schema (setup.sql + the unique key from Task 2),
then ingests 10,000 readings in one transaction. One warm-up run each, then 15 runs per variant,
alternating the two variants so both see the same machine load. The median is reported.
"""
import random, sqlite3, statistics, time
from datetime import datetime, timedelta
from pathlib import Path

HERE = Path(__file__).parent
SETUP = (HERE / "setup.sql").read_text()
TRIGGERS = (HERE / "triggers.sql").read_text()
N, RUNS = 10_000, 15

random.seed(42)
start = datetime(2026, 3, 3, 8, 0, 0)
ROWS = []
for i in range(N // 2):
    ts = (start + timedelta(seconds=i)).strftime("%Y-%m-%d %H:%M:%S")
    ROWS.append((1, ts, round(random.uniform(35, 60), 2), 1))     # temperature
    ROWS.append((2, ts, round(random.uniform(0.5, 2.5), 3), 1))   # vibration, some above 2.0


def fresh_db(with_alarm_trigger):
    con = sqlite3.connect(":memory:")
    con.executescript(SETUP)
    con.execute("PRAGMA foreign_keys = ON")
    con.execute("CREATE UNIQUE INDEX ux_reading_sensor_ts ON reading(sensor_id, ts)")
    con.executescript(TRIGGERS)
    if not with_alarm_trigger:
        con.execute("DROP TRIGGER trg_vib_alarm")
    con.executemany("INSERT INTO sensor VALUES (?, ?, ?, ?)",
                    [(1, "cnc-01", "temp_c", "degC"), (2, "cnc-01", "vib_rms", "mm/s")])
    con.commit()
    return con


def ingest_ms(with_alarm_trigger):
    con = fresh_db(with_alarm_trigger)
    t0 = time.perf_counter()
    with con:
        con.executemany("INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (?, ?, ?, ?)", ROWS)
    ms = (time.perf_counter() - t0) * 1000
    alarms = con.execute("SELECT COUNT(*) FROM alarm").fetchone()[0]
    con.close()
    return ms, alarms


print(f"Ingest of {N:,} readings, median of {RUNS} runs (SQLite {sqlite3.sqlite_version})")
variants = {"without alarm trigger": False, "with alarm trigger": True}
times = {label: [] for label in variants}
alarms = {}
for flag in variants.values():
    ingest_ms(flag)                                  # warm-up, not counted
for _ in range(RUNS):
    for label, flag in variants.items():             # alternate the variants
        ms, alarms[label] = ingest_ms(flag)
        times[label].append(ms)
results = {}
for label in variants:
    results[label] = statistics.median(times[label])
    print(f"  {label:22s} {results[label]:7.1f} ms   alarms raised: {alarms[label]}")
a, b = results["without alarm trigger"], results["with alarm trigger"]
print(f"  trigger cost: +{b - a:.1f} ms ({(b / a - 1) * 100:.0f}% slower), about {(b - a) / N * 1000:.2f} microseconds per row")
