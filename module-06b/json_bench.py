# module-06b/json_bench.py: run with  uv run python module-06b/json_bench.py
"""A JSON column in SQLite: store flexibly, query precisely, index deliberately."""
import json
import sqlite3
from pathlib import Path

here = Path(__file__).parent
con = sqlite3.connect(here / "polyglot.db")

con.executescript("""
DROP TABLE IF EXISTS device;
CREATE TABLE device(
    device_id INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    meta      TEXT NOT NULL CHECK (json_valid(meta))   -- it *is* JSON, enforced
) STRICT;
""")

rows = [
    ("cnc-01",    '{"vendor":"Siemens","firmware":"4.2","calibrated":"2026-01-10"}'),
    ("cnc-02",    '{"vendor":"Fanuc","firmware":"3.9"}'),
    ("molder-07", '{"vendor":"Arburg","firmware":"8.1","calibrated":"2025-11-02","nozzle_mm":2.5}'),
]
for i in range(4, 1001):
    meta = json.dumps({
        "vendor": ("Siemens", "Fanuc", "Arburg")[i % 3],
        "firmware": f"{i % 5}.{i % 10}",
    })
    rows.append((f"device-{i:04d}", meta))
con.executemany("INSERT INTO device(name, meta) VALUES (?, ?)", rows)

print("-- a path behaves like a column (first five rows)")
for row in con.execute(
        "SELECT name, json_extract(meta, '$.vendor') FROM device LIMIT 5"):
    print(row)

print("-- the ->> shorthand returns a scalar (first five rows)")
for row in con.execute("SELECT name, meta ->> '$.firmware' FROM device LIMIT 5"):
    print(row)

print("-- an object becomes rows")
for row in con.execute(
        "SELECT d.name, j.key, j.value FROM device d, json_each(d.meta) j "
        "WHERE d.name = 'cnc-01'"):
    print(row)

print("-- index the path you filter on, then prove it")
con.executescript("""
CREATE INDEX ix_device_vendor ON device(json_extract(meta, '$.vendor'));
""")
print(con.execute(
    "EXPLAIN QUERY PLAN SELECT name FROM device "
    "WHERE json_extract(meta, '$.vendor') = 'Fanuc'").fetchall())

print("-- now break it: the shorthand is a different expression")
print(con.execute(
    "EXPLAIN QUERY PLAN SELECT name FROM device "
    "WHERE meta ->> 'vendor' = 'Fanuc'").fetchall())

# Extra checks (mine): same answer from both expressions, and json_valid really rejects non-JSON.
a = con.execute("SELECT COUNT(*) FROM device WHERE json_extract(meta, '$.vendor') = 'Fanuc'").fetchone()[0]
b = con.execute("SELECT COUNT(*) FROM device WHERE meta ->> 'vendor' = 'Fanuc'").fetchone()[0]
print(f"-- same result? json_extract: {a} rows, ->>: {b} rows")
try:
    con.execute("INSERT INTO device(name, meta) VALUES ('bad', 'vendor=Siemens')")
except sqlite3.IntegrityError as e:
    print("-- non-JSON rejected:", e)
print("-- a new vendor field needs no migration:")
con.execute("""INSERT INTO device(name, meta) VALUES ('laser-01', '{"vendor":"Trumpf","laser_kw":6}')""")
print(con.execute("SELECT name, meta ->> 'laser_kw' FROM device WHERE name = 'laser-01'").fetchone())
con.commit()
