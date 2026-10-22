-- Task 1: ask the LLM, then check the plan
-- Run from the repo root:  sqlite3 module-03/warehouse.db ".read module-03/task1-llm-query.sql"
.echo on
.mode column
.headers on

-- A. The LLM's query (as generated): year filter with strftime()
.timer on
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
.timer off

EXPLAIN QUERY PLAN
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

-- B. Reference query from the workbook: year filter as a plain range on the column
.timer on
SELECT c.city, COUNT(DISTINCT c.customer_id) AS customers,
       SUM(ol.qty * p.price) AS revenue
FROM customer c
JOIN orders o     ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id = o.order_id
JOIN product p    ON p.product_id = ol.product_id
WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
GROUP BY c.city
ORDER BY revenue DESC;
.timer off

EXPLAIN QUERY PLAN
SELECT c.city, COUNT(DISTINCT c.customer_id) AS customers,
       SUM(ol.qty * p.price) AS revenue
FROM customer c
JOIN orders o     ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id = o.order_id
JOIN product p    ON p.product_id = ol.product_id
WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
GROUP BY c.city
ORDER BY revenue DESC;

-- C. Sanity checks
-- how many orders are in 2025 vs. the whole table?
SELECT COUNT(*) AS orders_2025 FROM orders WHERE ordered_on >= '2025-01-01' AND ordered_on < '2026-01-01';
SELECT MIN(ordered_on) AS first_day, MAX(ordered_on) AS last_day FROM orders;
-- does every city really have 500 customers?
SELECT city, COUNT(*) AS customers_in_table FROM customer GROUP BY city;
-- without DISTINCT the "customers" column counts order lines, not people
SELECT c.city, COUNT(c.customer_id) AS not_distinct
FROM customer c
JOIN orders o      ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id   = o.order_id
WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
GROUP BY c.city;
