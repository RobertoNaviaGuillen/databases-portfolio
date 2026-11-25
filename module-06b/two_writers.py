# module-06b/two_writers.py: run with  uv run python module-06b/two_writers.py
"""Task 1 fallback (local version): two writers, one row, in SQLite.

The workbook's fallback: two connections, one BEGIN IMMEDIATE, the second write gets
'database is locked'. Then the lost update: both read, both add 1, both write.
"""
import sqlite3
from pathlib import Path

db = Path(__file__).with_name("two_writers.db")
db.unlink(missing_ok=True)
setup = sqlite3.connect(db)
setup.executescript("""
CREATE TABLE machine(
    machine_id      INTEGER PRIMARY KEY,
    site            TEXT NOT NULL,
    parts_produced  INTEGER NOT NULL DEFAULT 0
);
INSERT INTO machine VALUES (1, 'guetersloh', 0);
""")
setup.close()

# isolation_level=None: we control BEGIN/COMMIT ourselves. timeout=0: do not wait for the lock.
a = sqlite3.connect(db, isolation_level=None, timeout=0)
b = sqlite3.connect(db, isolation_level=None, timeout=0)

print("== 1. Two writers, one row")
a.execute("BEGIN IMMEDIATE")
a.execute("UPDATE machine SET parts_produced = parts_produced + 1 WHERE machine_id = 1")
print("writer A: BEGIN IMMEDIATE + UPDATE done, not committed yet")
try:
    b.execute("BEGIN IMMEDIATE")
    print("writer B: got the write lock (unexpected)")
except sqlite3.OperationalError as e:
    print("writer B:", e)
print("writer B can still READ:", b.execute("SELECT parts_produced FROM machine WHERE machine_id = 1").fetchone()[0],
      "(the old value; A's change is not committed)")
a.execute("COMMIT")
b.execute("BEGIN IMMEDIATE")
b.execute("UPDATE machine SET parts_produced = parts_produced + 1 WHERE machine_id = 1")
b.execute("COMMIT")
print("after A commits, B retries and succeeds. parts_produced =",
      a.execute("SELECT parts_produced FROM machine WHERE machine_id = 1").fetchone()[0], "(expected 2)")

print("== 2. Lost update: read in the app, add 1 in the app, write back")
start = a.execute("SELECT parts_produced FROM machine WHERE machine_id = 1").fetchone()[0]
va = a.execute("SELECT parts_produced FROM machine WHERE machine_id = 1").fetchone()[0]   # A reads 2
vb = b.execute("SELECT parts_produced FROM machine WHERE machine_id = 1").fetchone()[0]   # B reads 2
a.execute("UPDATE machine SET parts_produced = ? WHERE machine_id = 1", (va + 1,))         # A writes 3
b.execute("UPDATE machine SET parts_produced = ? WHERE machine_id = 1", (vb + 1,))         # B writes 3
end = a.execute("SELECT parts_produced FROM machine WHERE machine_id = 1").fetchone()[0]
print(f"both added 1 to {start}: expected {start + 2}, got {end}. One update was lost.")
print("The database did not prevent it: each UPDATE was valid on its own. The fix is to let the")
print("database do the arithmetic (SET parts_produced = parts_produced + 1), as in part 1.")
a.close(); b.close()
db.unlink()
