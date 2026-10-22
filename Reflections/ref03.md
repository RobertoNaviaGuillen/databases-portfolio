# Reflection 3 (Module 3): LLM-Assisted SQL & Query Profiling

Back to [Module 3](../module-03/README.md)

## What worked?

Understanding why indexes matter, and that they are **not always useful**. Seeing it measured on a real database made it stick: an index on the order date made a single-day lookup about 15× faster, and I can now explain the difference between a `SCAN` (reading every row) and a `SEARCH` (jumping straight to the rows through an index).

## What broke? What was difficult?

Honestly, almost everything in this module was hard for me: joining four tables, reading query plans, the benchmark, and the injection drill were all new. My prediction in Task 1 was wrong (I expected `customer` to be scanned; it was `order_line`, the only table without a primary key). The relational algebra symbols (σ, π, ⋈, γ) are still not clear to me; I can read the expression from Task 4, but I could not write one on my own yet.

## How did my mental model shift?

Before, I assumed that adding an index always makes a database faster. Now I know that an index **changes the plan**, but it does not guarantee a speedup: when a query needs most of the rows anyway, reading the table once from start to end can be cheaper than thousands of jumps through an index.

## How did I verify AI suggestions?

The biggest surprise was the index that made everything slower. The LLM suggested three indexes for the dashboard query; I tested them **one at a time**, with the median of 5 runs and the `EXPLAIN QUERY PLAN` after each step. One of them (`ix_orderline_order`) changed the plan to an index-driven join and made the query about **8× slower** (161 ms → 1,266 ms). I also checked the LLM's query itself: it returned the right numbers (same as the reference query, and `DISTINCT` was needed), but it wrapped the date column in a function (`strftime`), which prevents an index on that column from being used.

## Help and extra work

- I used **Claude (AI)** as an assistant to build the database, write the benchmark script and run the tasks, and it explained each result to me in simple terms.
- Still to do: the Pod Study tasks (A-C) with my pod, which need the Module 2 database, and practising relational algebra before the checkpoint.
