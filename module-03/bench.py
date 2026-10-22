"""Task 2: index benchmark, one index at a time.

Run from the repo root:  uv run python module-03/bench.py
For every step it prints the EXPLAIN QUERY PLAN and the median time of each query.
"""
import sqlite3, statistics, time
from pathlib import Path

DB = Path(__file__).with_name("warehouse.db")
RUNS = 5          # median of 5 runs (the course asks for >= 3)
BATCH = 200       # fast queries are repeated in a batch, then divided (amortized timing)

QUERIES = {
    "dashboard (range)": ("""
        SELECT c.city, COUNT(DISTINCT c.customer_id) AS customers, SUM(ol.qty * p.price) AS revenue
        FROM customer c
        JOIN orders o      ON o.customer_id = c.customer_id
        JOIN order_line ol ON ol.order_id   = o.order_id
        JOIN product p     ON p.product_id  = ol.product_id
        WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
        GROUP BY c.city ORDER BY revenue DESC""", 1),
    "single day": ("""
        SELECT o.order_id, o.ordered_on, c.name
        FROM orders o JOIN customer c ON c.customer_id = o.customer_id
        WHERE o.ordered_on = '2026-02-14'""", BATCH),
    "single day, date() wrapped": ("""
        SELECT o.order_id, o.ordered_on, c.name
        FROM orders o JOIN customer c ON c.customer_id = o.customer_id
        WHERE date(o.ordered_on) = '2026-02-14'""", BATCH),
    "one product": ("""
        SELECT SUM(qty) FROM order_line WHERE product_id = 37""", BATCH),
}

STEPS = [
    ("baseline (no extra index)", None),
    ("+ ix_orders_ordered_on", "CREATE INDEX ix_orders_ordered_on ON orders(ordered_on)"),
    ("+ ix_orderline_order", "CREATE INDEX ix_orderline_order ON order_line(order_id)"),
    ("+ ix_orderline_product", "CREATE INDEX ix_orderline_product ON order_line(product_id)"),
]


def median_ms(conn, sql, batch):
    conn.execute(sql).fetchall()                      # warm-up: the first run pays for the file cache
    times = []
    for _ in range(RUNS):
        t0 = time.perf_counter()
        for _ in range(batch):
            conn.execute(sql).fetchall()
        times.append((time.perf_counter() - t0) / batch * 1000)
    return statistics.median(times)


def plan(conn, sql):
    return [row[3] for row in conn.execute("EXPLAIN QUERY PLAN " + sql)]


conn = sqlite3.connect(DB)
for ix in ("ix_orders_ordered_on", "ix_orderline_order", "ix_orderline_product"):
    conn.execute(f"DROP INDEX IF EXISTS {ix}")       # reset the benchmark state

results = {}
for step, ddl in STEPS:
    if ddl:
        conn.execute(ddl)
    print(f"\n===== {step} =====")
    for name, (sql, batch) in QUERIES.items():
        ms = median_ms(conn, sql, batch)
        results[(step, name)] = ms
        print(f"\n[{name}]  median {ms:.3f} ms")
        for line in plan(conn, sql):
            print("   ", line)

print("\n===== summary: median ms =====")
print(f"{'step':28s}" + "".join(f"{n:>28s}" for n in QUERIES))
for step, _ in STEPS:
    print(f"{step:28s}" + "".join(f"{results[(step, n)]:28.3f}" for n in QUERIES))

for ix in ("ix_orders_ordered_on", "ix_orderline_order", "ix_orderline_product"):
    conn.execute(f"DROP INDEX IF EXISTS {ix}")       # leave the database as setup.sql built it
conn.close()
