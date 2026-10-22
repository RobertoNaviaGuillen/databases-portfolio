# Module 3: LLM-Assisted SQL & Query Profiling

Course: Databases (HSBI) · Session 3 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/03-llm-assisted-sql-and-query-profiling.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Build complex **DQL** queries: joins, aggregation with `GROUP BY`/`HAVING`, subqueries, and window functions.
2. Read **`EXPLAIN QUERY PLAN`** as *primary evidence*: say what the engine will do for a given query, tell a `SCAN` from a `SEARCH`, and a table lookup from a covering index.
3. **Benchmark** the effect of an index and explain when the planner ignores one.
4. Generate a query with an **LLM**, then **verify** it: correctness, performance, and edge cases.
5. **Prevent SQL injection** with bound parameters and demonstrate why string concatenation is exploitable.

## Tasks

- [ ] Pod Study, Tasks A-C (plan safari, algebra check, share): in class with the pod; they use `Module02/legacy.db`, which I have not built yet (Module 2 is still pending).
- [x] Setup: [setup.sql](setup.sql) builds `warehouse.db` (not committed; rebuild with `sqlite3 module-03/warehouse.db ".read module-03/setup.sql"`): 2,000 customers, 500 products, 60,000 orders, 240,000 order lines.
- [x] Task 1: LLM query and plan ([queries](task1-llm-query.sql), [output](task1-results.txt))
- [x] Task 2: Index benchmark ([bench.py](bench.py), [output](bench-results.txt))
- [x] Task 3: Injection drill ([injection_demo.py](injection_demo.py), [output](injection-results.txt))
- [x] Task 4: One query, from algebra to plan ([check](task4-algebra-check.sql), [output](task4-results.txt))
- [ ] Task 5 (Stretcher): window functions
- [x] Harvest notes: [sql-notes.md](sql-notes.md) · Reflection: [ref03.md](../Reflections/ref03.md)

## Task 1: Ask the LLM, then check the plan

**LLM used:** Claude. **Prompt** (from the workbook):

> SQLite schema: `customer(customer_id, name, city)`, `product(product_id, sku, price)`, `orders(order_id, customer_id, ordered_on, status)`, `order_line(order_id, product_id, qty)`. Write a query that returns, for each city, the number of distinct customers and the total revenue (sum of `qty*price`) of orders placed in 2025, ordered by revenue descending.

**Generated SQL:**

```sql
SELECT c.city,
       COUNT(DISTINCT c.customer_id) AS customers,
       SUM(ol.qty * p.price)         AS revenue
FROM customer c
JOIN orders o      ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id   = o.order_id
JOIN product p     ON p.product_id  = ol.product_id
WHERE strftime('%Y', o.ordered_on) = '2025'
GROUP BY c.city
ORDER BY revenue DESC;
```

**My prediction:** `customer` would be the table read completely (`SCAN`). **Wrong.**

**Actual plan:**

```
|--SCAN ol
|--SEARCH o USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
|--SEARCH p USING INTEGER PRIMARY KEY (rowid=?)
|--USE TEMP B-TREE FOR GROUP BY
|--USE TEMP B-TREE FOR count(DISTINCT)
`--USE TEMP B-TREE FOR ORDER BY
```

`order_line` is the only table without its own primary key, so there is no way to jump into it: the engine starts there, reads all 240,000 rows, and for each row looks up the order, the customer and the product through their primary keys (`SEARCH`). `customer` is reached *from* `orders` via `customer_id`, which is why my prediction was wrong.

| City | Customers | Revenue |
|---|---|---|
| Bielefeld | 500 | 11,242,176 |
| Gütersloh | 500 | 8,422,344 |
| Münster | 500 | 5,493,504 |
| Paderborn | 500 | 2,815,656 |

**Correctness:** the result is identical to the workbook's reference query. `DISTINCT` is needed: without it the "customers" column counts ~40,000 order lines per city instead of 500 people. The year filter matters (orders go up to 2026-06-24; 40,575 of 60,000 orders are in 2025). **Weak spot:** the model wrapped the column in a function, `strftime('%Y', ordered_on)`. That is correct, but a function around the column prevents any index on `ordered_on` from being used (proved in Task 2). The reference uses a plain range, `ordered_on >= '2025-01-01' AND ordered_on < '2026-01-01'`.

## Task 2: Index benchmark

**LLM suggestion:** add `orders(ordered_on)`, `order_line(order_id)` and `order_line(product_id)`. I tested them **one at a time**. Median of 5 runs (fast queries timed as a batch of 200 and divided), in ms:

| Step | Dashboard (2025 range) | Single day | Single day, `date()` wrapped | One product |
|---|---|---|---|---|
| Baseline | 161.2 | 3.32 | 7.74 | 11.45 |
| + `ix_orders_ordered_on` | 165.6 | **0.23** | 9.48 | 12.09 |
| + `ix_orderline_order` | **1,266.4** | 0.22 | 7.84 | 11.72 |
| + `ix_orderline_product` | 1,243.9 | 0.22 | 8.42 | **2.07** |

What the plans show ([full output](bench-results.txt)):

- **The index that wins:** single day goes from `SCAN o` to `SEARCH o USING INDEX ix_orders_ordered_on (ordered_on=?)`, about **15× faster**.
- **The index that makes it worse:** with `ix_orderline_order` the dashboard flips to an index-driven join (`SEARCH o USING INDEX ix_orders_ordered_on (ordered_on>? AND ordered_on<?)` → `SEARCH ol USING INDEX ix_orderline_order`) and becomes **~8× slower**. The filter keeps 2/3 of all orders, so ~160,000 single index lookups cost more than one sequential scan of `order_line`. The plan changed, the time got worse: an index changes the plan, it does not guarantee a speedup.
- **`ix_orders_ordered_on` alone does not change the dashboard plan** (it still starts with `SCAN ol`).
- **A function defeats the index:** `WHERE date(ordered_on) = '2026-02-14'` stays `SCAN o` even with the index. This is exactly the pattern the LLM produced in Task 1.
- **"Useless for this query", not "useless":** `ix_orderline_product` never appears in the dashboard plan (the engine reaches `product` through its primary key), but for `WHERE product_id = 37` it gives `SEARCH order_line USING INDEX ix_orderline_product` and goes from 11.4 ms to 2.1 ms.

## Task 3: Injection drill

Output ([full](injection-results.txt)):

```
normal   : [(1, 'Customer 1')]
injected : [(1, 'Customer 1'), (2, 'Customer 2'), (3, 'Customer 3')] ...
safe     : []
O'Brien vulnerable: crashed with near "Brien": syntax error
O'Brien safe      : []
```

**Payload:** `' OR '1'='1` turns the query into `WHERE name = '' OR '1'='1'`, which is always true and returns every customer. A real name like `O'Brien` closes the quote early and crashes the query (the support agent's bug from the story). With a bound parameter (`?`), the SQL and the value are sent separately, so the value is only ever data.

**Why escaping `'` by hand is not a real fix:** it breaks legitimate data (`O'Brien` is a real name), it only covers the cases you thought of (numeric contexts without quotes, identifiers, other encodings), and it makes *me* responsible for getting every case right. With bound parameters the database driver guarantees the separation of code and data.

## Task 4: One query, from algebra to plan

**SQL:**

```sql
SELECT o.order_id, o.ordered_on, c.name
FROM orders o JOIN customer c ON c.customer_id = o.customer_id
WHERE o.ordered_on = '2026-02-14';
```

**Relational algebra:**

π<sub>order_id, ordered_on, name</sub> ( σ<sub>ordered_on = '2026-02-14'</sub> ( orders ⋈<sub>customer_id</sub> customer ) )

`⋈` = the `JOIN ... ON`, `σ` = the `WHERE`, `π` = the `SELECT` list.

**Check:** the equivalent form with the selection pushed below the join, π( σ(orders) ⋈ customer ), returns the same 111 rows, and `EXCEPT` in both directions returns 0 rows. Both versions get the same plan (`SCAN o` → `SEARCH c USING INTEGER PRIMARY KEY`): the planner pushes the filter down by itself.

**Dashboard from Task 1:**

γ<sub>city; COUNT(DISTINCT customer_id), SUM(qty·price)</sub> ( σ<sub>'2025-01-01' ≤ ordered_on < '2026-01-01'</sub> ( customer ⋈ orders ⋈ order_line ⋈ product ) )

`ORDER BY` has no operator in basic relational algebra (relations are unordered sets).
