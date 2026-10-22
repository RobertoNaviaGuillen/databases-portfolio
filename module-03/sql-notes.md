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

## Task A: Plan safari (on Module 2's `legacy.db`)

Queries, predictions and plans: [plan-safari.sql](plan-safari.sql) ([output](plan-safari-results.txt)).

| Query | My prediction | No index | With `ix_job_tech` on `maint_job(technician)` |
|---|---|---|---|
| A `technician = 'Beier'` | SCAN | SCAN ✅ | **SEARCH** `USING INDEX ix_job_tech (technician=?)` |
| B `machine_name = 'cnc-02'` | SEARCH | **SCAN** ❌ | SCAN |
| C `technician LIKE '%ei%'` | SCAN | SCAN ✅ | SCAN |

- **My wrong prediction (B):** the legacy tables have **no primary key and no index at all**, so there is nothing to search with; every query on them is a `SCAN`.
- **Only A changed:** an index helps only the column it was built for. B filters `machine`, a different table and column.
- **C did not use the index:** a leading wildcard (`'%ei%'`, "ei anywhere") cannot use an alphabetically sorted index, like looking for surnames with "ei" in the middle of a phone book.

**Breaking the index on purpose:**

| WHERE | Plan | Why |
|---|---|---|
| `lower(technician) = 'beier'` | SCAN | a function around the column hides it from the index (same as `date(ordered_on)` in Task 2) |
| `technician LIKE 'Bei%'` | SCAN | surprise: even without a leading wildcard, SQLite's `LIKE` is case-insensitive and the index is not, so it is not used |
| `technician >= 'Bei' AND technician < 'Bej'` | **SEARCH** `(technician>? AND technician<?)` | the same prefix written as a range does use the index |

## Task B: Algebra check

Query A from the safari: `SELECT * FROM maint_job WHERE technician = 'Beier';`

| | Expression |
|---|---|
| **My first attempt** | `π * from maint_job σ technician = 'Beier'` |
| **LLM translation** | σ<sub>technician = 'Beier'</sub>(maint_job) |

**The diff (my gap, not the model's):** I had the right pieces but wrote them in **SQL order**. In algebra, (1) `SELECT *` needs **no π**, because π is only for keeping *some* columns; (2) there is no `from`, because the table goes **inside the parentheses**; (3) the form is *symbol, condition, (table)*.

**Second practice:** `SELECT machine_name FROM machine WHERE site = 'Gütersloh';`

| | Expression |
|---|---|
| My attempt | π<sub>machine_name</sub>( σ<sub>machine</sub>( Gutersloh ) ) |
| Correct | π<sub>machine_name</sub>( σ<sub>site = 'Gütersloh'</sub>( machine ) ) |

The structure (π outside, σ inside) and the π part were right this time; I swapped the condition and the table. **Trick:** what comes after `WHERE` goes under σ; what comes after `FROM` goes inside the parentheses.

## Task C: Explain & share (with my pod mates)

I compared my plan safari with [Leviscus Njeru](https://github.com/leviscusgnjeru/databases) ([his Module 3 notes](https://github.com/leviscusgnjeru/databases/blob/main/Module03/sql-notes.md)) and [Ian Okach](https://github.com/Okach81/Databases_ianportfolio).

**SQLite version:** mine is 3.54.0. Leviscus did not record his. Ian has not documented his plans yet, so I ran my [plan-safari.sql](plan-safari.sql) against a copy of **his** `legacy.db`: the plans were identical to mine (same data, same SQLite build on my machine).

| Query | Leviscus | Me |
|---|---|---|
| `technician = 'Beier'` | SCAN → SEARCH with `ix_job_tech` | SCAN → SEARCH |
| `machine_name = 'cnc-02'` | SCAN → SCAN | SCAN → SCAN |
| `technician LIKE '%ei%'` | SCAN → SCAN | SCAN → SCAN |
| function on the column | `UPPER(technician)` → SCAN | `lower(technician)` → SCAN |

**Same plans for every query we both ran.** Differences were in what we tested and recorded:

- I wrote my **predictions** down first (and got B wrong); Leviscus recorded observations only.
- I additionally found that `LIKE 'Bei%'` (no leading wildcard) **also** stays `SCAN`, while the same prefix written as a range (`>= 'Bei' AND < 'Bej'`) uses the index. That surprised the pod most.
- Leviscus's algebra example, π<sub>technician</sub>(σ<sub>machine_name='cnc-01'</sub>(maint_job)), is correct: it returns Beier and Werther on the sample data.

**What we agree on:**

1. The plan is the evidence of what SQLite does: `SCAN` reads everything, `SEARCH` uses an index or key.
2. An index helps only queries on **its own column**, used **as is**: a different table, a leading wildcard or a function around the column all stay `SCAN`.
3. A changed plan is not, on its own, proof of a faster query; timing is separate evidence (my warehouse benchmark had an index that made a query ~8× slower).

**Still open:** why SQLite's case-insensitive `LIKE` does not use a normal index even for a prefix (`'Bei%'`), and what kind of index would let it.

## Predictions vs. reality

| Prediction | Reality | Why |
|---|---|---|
| Task 1: `customer` would be scanned | `order_line` was scanned | `order_line` has no primary key; `customer` is reached from `orders` through `customer_id` |
| Task A: `machine_name = 'cnc-02'` would be a `SEARCH` | `SCAN` | `legacy.db` has no primary keys and no indexes |
| Adding the indexes the LLM suggested would make the dashboard faster | `ix_orderline_order` made it ~8× slower (161 ms → 1,266 ms) | the filter keeps 2/3 of the orders, so ~160,000 single index lookups cost more than one sequential scan |

## Verified LLM answers

- The LLM's year filter `strftime('%Y', ordered_on) = '2025'` gives the correct result, but wrapping the column in a function blocks any index on `ordered_on` (`date(ordered_on) = ...` stayed `SCAN o` with the index present). A plain range (`>= '2025-01-01' AND < '2026-01-01'`) can use it.
- The LLM's index list was not trustworthy as a package: one index helped a different query (single day, ~15× faster), one made the dashboard slower, and one was only useful for a query that filters on `product_id`.
