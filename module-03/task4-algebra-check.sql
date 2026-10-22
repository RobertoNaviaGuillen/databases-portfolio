-- Task 4: one query, from algebra to plan
-- Run from the repo root:  sqlite3 module-03/warehouse.db ".read module-03/task4-algebra-check.sql"
--
-- Algebra:  π[order_id, ordered_on, name] ( σ[ordered_on = '2026-02-14'] ( orders ⋈[customer_id] customer ) )
-- Equivalent (selection pushed below the join):
--           π[order_id, ordered_on, name] ( σ[ordered_on = '2026-02-14'](orders) ⋈[customer_id] customer )
.echo on
.mode column
.headers on

-- A. As written: join first, then filter
SELECT COUNT(*) AS rows_a FROM (
  SELECT o.order_id, o.ordered_on, c.name
  FROM orders o JOIN customer c ON c.customer_id = o.customer_id
  WHERE o.ordered_on = '2026-02-14');

-- B. Selection pushed down: filter orders first, then join
SELECT COUNT(*) AS rows_b FROM (
  SELECT o.order_id, o.ordered_on, c.name
  FROM (SELECT * FROM orders WHERE ordered_on = '2026-02-14') o
  JOIN customer c ON c.customer_id = o.customer_id);

-- C. Same rows? (EXCEPT both ways must return nothing)
SELECT COUNT(*) AS only_in_a FROM (
  SELECT o.order_id, o.ordered_on, c.name FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14'
  EXCEPT
  SELECT o.order_id, o.ordered_on, c.name FROM (SELECT * FROM orders WHERE ordered_on = '2026-02-14') o JOIN customer c ON c.customer_id = o.customer_id);
SELECT COUNT(*) AS only_in_b FROM (
  SELECT o.order_id, o.ordered_on, c.name FROM (SELECT * FROM orders WHERE ordered_on = '2026-02-14') o JOIN customer c ON c.customer_id = o.customer_id
  EXCEPT
  SELECT o.order_id, o.ordered_on, c.name FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14');

-- D. The planner does the push-down by itself: both plans are identical
EXPLAIN QUERY PLAN
SELECT o.order_id, o.ordered_on, c.name
FROM orders o JOIN customer c ON c.customer_id = o.customer_id
WHERE o.ordered_on = '2026-02-14';
EXPLAIN QUERY PLAN
SELECT o.order_id, o.ordered_on, c.name
FROM (SELECT * FROM orders WHERE ordered_on = '2026-02-14') o
JOIN customer c ON c.customer_id = o.customer_id;
