"""Task 2: replay-safe CSV ingestion with UPSERT and executemany.

Run from the repo root:  uv run python module-04/ingest.py
It loads readings.csv into edge.db TWICE and prints the row count after each run.
For comparison it also loads the same file twice into a table WITHOUT a natural key.
"""
import csv, sqlite3
from pathlib import Path

HERE = Path(__file__).parent
DB = HERE / "edge.db"
CSV = HERE / "readings.csv"

UPSERT = """
    INSERT INTO reading(sensor_id, ts, value, interval_s)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(sensor_id, ts) DO UPDATE SET value = excluded.value
"""


def load_rows():
    with CSV.open(newline="") as f:
        return [(int(r["sensor_id"]), r["ts"], float(r["value"]), int(r["interval_s"]))
                for r in csv.DictReader(f)]


def ingest(con, rows):
    with con:                                   # one transaction per run
        con.executemany(UPSERT, rows)


rows = load_rows()
con = sqlite3.connect(DB)
con.execute("PRAGMA foreign_keys = ON")
print(f"CSV rows: {len(rows)}")
print(f"before:      {con.execute('SELECT COUNT(*) FROM reading').fetchone()[0]} rows in reading")
for run in (1, 2):
    ingest(con, rows)
    print(f"after run {run}: {con.execute('SELECT COUNT(*) FROM reading').fetchone()[0]} rows in reading")

# The same double run into a table without a natural key: every replay duplicates.
con.execute("CREATE TEMP TABLE naive(sensor_id INTEGER, ts TEXT, value REAL, interval_s INTEGER)")
for run in (1, 2):
    con.executemany("INSERT INTO naive VALUES (?, ?, ?, ?)", rows)
    print(f"naive table (plain INSERT, no key) after run {run}: "
          f"{con.execute('SELECT COUNT(*) FROM naive').fetchone()[0]} rows")
con.close()
