# SQL notes: Module 3

Back to [Module 3](README.md)

## Harvest (Round 2)

### One construct I can explain in one sentence: `SCAN` vs. `SEARCH`

`SCAN` means the engine reads **every row** of the table, like leafing through a whole cookbook to find one recipe; `SEARCH` means it uses an index (or the primary key) to **jump straight** to the rows it needs, like looking the recipe up in the index at the back of the book.

In the Task 1 plan, `order_line` was the only `SCAN` because it is the only table without its own primary key, so there is nothing to jump into; every other table was reached with `SEARCH ... USING INTEGER PRIMARY KEY`.

### One construct that is still opaque: relational algebra symbols

The symbols σ, π, ⋈ and γ and how to write a query with them. What I have so far:

| Symbol | Means | SQL |
|---|---|---|
| σ | filter rows | `WHERE` |
| π | choose columns | `SELECT` list |
| ⋈ | join two tables | `JOIN ... ON` |
| γ | group and aggregate | `GROUP BY` + `COUNT`/`SUM` |

I can read the Task 4 expression from the inside out, but I could not yet write one on my own for a new query. To practise before the checkpoint.

## Predictions vs. reality

| Prediction | Reality | Why |
|---|---|---|
| Task 1: `customer` would be scanned | `order_line` was scanned | `order_line` has no primary key; `customer` is reached from `orders` through `customer_id` |
| Adding the indexes the LLM suggested would make the dashboard faster | `ix_orderline_order` made it ~8× slower (161 ms → 1,266 ms) | the filter keeps 2/3 of the orders, so ~160,000 single index lookups cost more than one sequential scan |

## Verified LLM answers

- The LLM's year filter `strftime('%Y', ordered_on) = '2025'` gives the correct result, but wrapping the column in a function blocks any index on `ordered_on` (`date(ordered_on) = ...` stayed `SCAN o` with the index present). A plain range (`>= '2025-01-01' AND < '2026-01-01'`) can use it.
- The LLM's index list was not trustworthy as a package: one index helped a different query (single day, ~15× faster), one made the dashboard slower, and one was only useful for a query that filters on `product_id`.
