# module-06a/boundary.py: run with  uv run python module-06a/boundary.py
"""1,000 single-row writes and lookups: the workload DuckDB is not built for.
Also the executemany variant (batched inserts), and RUNS repeats with the median."""
import sqlite3
import statistics
import time

import duckdb

N = 1_000
RUNS = 5
ROWS = [(i, f"k{i}", i * 1.5) for i in range(N)]


def lookups(con):
    t0 = time.perf_counter()
    for i in range(N):
        con.execute("SELECT v FROM s WHERE id = ?", (i,)).fetchone()
    return (time.perf_counter() - t0) * 1000


def run_sqlite(batched):
    con = sqlite3.connect(":memory:")
    con.execute("CREATE TABLE s(id INTEGER PRIMARY KEY, k TEXT, v REAL)")
    t0 = time.perf_counter()
    if batched:
        con.executemany("INSERT INTO s VALUES (?, ?, ?)", ROWS)
    else:
        for row in ROWS:
            con.execute("INSERT INTO s VALUES (?, ?, ?)", row)
    con.commit()
    return (time.perf_counter() - t0) * 1000, lookups(con)


def run_duckdb(batched):
    con = duckdb.connect()
    con.execute("CREATE TABLE s(id INTEGER PRIMARY KEY, k TEXT, v DOUBLE)")
    t0 = time.perf_counter()
    if batched:
        con.executemany("INSERT INTO s VALUES (?, ?, ?)", ROWS)
    else:
        for row in ROWS:
            con.execute("INSERT INTO s VALUES (?, ?, ?)", row)
    return (time.perf_counter() - t0) * 1000, lookups(con)


def median_of(fn, batched):
    results = [fn(batched) for _ in range(RUNS)]
    return statistics.median(r[0] for r in results), statistics.median(r[1] for r in results)


si, sl = median_of(run_sqlite, False)
di, dl = median_of(run_duckdb, False)
sb, _ = median_of(run_sqlite, True)
db, _ = median_of(run_duckdb, True)
print(f"{N:,} statements each, median of {RUNS} runs")
print(f"inserts, one execute per row   sqlite {si:8.1f} ms | duckdb {di:8.1f} ms | {di / si:6.0f}x")
print(f"inserts, executemany (batched) sqlite {sb:8.1f} ms | duckdb {db:8.1f} ms | {db / sb:6.0f}x")
print(f"lookups by primary key         sqlite {sl:8.1f} ms | duckdb {dl:8.1f} ms | {dl / sl:6.0f}x")


# What would have to change in the application: send the 1,000 rows as ONE set-based statement.
def duckdb_one_statement():
    con = duckdb.connect()
    con.execute("CREATE TABLE s(id INTEGER PRIMARY KEY, k TEXT, v DOUBLE)")
    t0 = time.perf_counter()
    con.execute(f"INSERT INTO s SELECT i, 'k' || i, i * 1.5 FROM range({N}) t(i)")
    return (time.perf_counter() - t0) * 1000


one = statistics.median(duckdb_one_statement() for _ in range(RUNS))
print(f"inserts, one set-based INSERT  duckdb {one:8.1f} ms")
