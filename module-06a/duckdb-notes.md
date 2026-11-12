# Module 6a: DuckDB notes

Back to [Module 6a](README.md)

**Input from Module 5:** my own `module-05/normalize.db` (not the numbers on the board). Note: its `report_jobpart` already contains my Round 5 changes, so `cnc-02` is in Bielefeld and `ix_report_machine` is dropped. Both engines below read the same data, so this does not affect the comparison.

## Round 1: Build the history

[prepare.py](prepare.py) · [output](prepare-results.txt)

| | Value |
|---|---|
| `report_history` rows | **2,000,000** |
| CSV of the 200k base table | 10,801,002 bytes (10.8 MB) |

- **Why exactly 10 × 200,000?** The recursive CTE produces `k = 0..9`, and every one of the 200,000 rows of `report_jobpart` is copied once per `k` (a cross join). `job_id + k * 1000000` keeps the job ids unique, and the date moves forward `k * 91` days.
- **Windows problem:** the first run failed in Round 2 with `Invalid unicode (byte sequence mismatch) detected. This file is not utf-8 encoded.` On Windows, Python's `open()` defaults to the cp1252 encoding, so the "ü" of Gütersloh was written as a byte DuckDB rejects. Fix: `open(..., encoding="utf-8")` in `prepare.py`.
- **90 vs. 91 days** ([output](round1-discussion-results.txt)): the base data covers 90 days (`n % 90` = days 0 to 89). Shifting by 91 days leaves **one empty day per quarter**: 900 distinct days over a 909-day calendar range. 91 days = 13 weeks, so every copy keeps the same weekdays; with 90 the days would join without a gap, but each quarter would start on a different weekday.
- **`'+1 month'` vs. `'+91 days'`:** months are not all the same length. `date('2026-01-31', '+1 month')` gives `2026-03-03` (SQLite rolls "31 February" over into March), while `'+91 days'` is always exactly 91 days.

## Round 2: Convert to Parquet

[to_parquet.py](to_parquet.py) · [output](to-parquet-results.txt)

Both sides were checked before timing anything:

| | Rows | `SUM(part_price)` | First date | Last date |
|---|---|---|---|---|
| SQLite `report_history` | 2,000,000 | 21,000,000.0 | 2026-01-01 | 2028-06-27 |
| Parquet | 2,000,000 | 21,000,000.0 | 2026-01-01 | 2028-06-27 |

| File | Size |
|---|---|
| `history.db` (SQLite) | **112.65 MB** |
| `report_history.parquet` | **2.40 MB** (47× smaller) |

- **Why so much smaller?** Parquet stores each column together and compresses it per column. Columns like `site`, `technician` and `part_no` repeat the same few values millions of times, and compression loves repetition. SQLite stores whole rows, uncompressed.
- **How to prove it is the same data** if `history.db` disappeared: a row count alone would not convince me (2,000,000 rows of anything would pass). The row count **plus** `SUM(part_price)` and the date range is much stronger; a checksum over all columns, recomputed from the script, would be the strongest.
- **Reproducibility:** a podmate can rebuild the file from `prepare.py` and `to_parquet.py` alone, as long as they have `module-05/normalize.db`.

## Round 3: The race

[race.py](race.py) · [output](race-results.txt)

**My prediction:** DuckDB 10 to 20 times faster. **Result: much more**, 75 to 107 times.

| Query | SQLite median [min-max] | DuckDB median [min-max] | Ratio | Same result? |
|---|---|---|---|---|
| dashboard (cost per machine/site/technician) | 2,480.2 ms [2,444.9-2,636.2] | 33.3 ms [30.8-33.5] | **74.5×** | yes, 350 rows |
| monthly (jobs and cost per month and machine) | 3,073.1 ms [2,781.0-3,301.4] | 28.8 ms [26.3-33.9] | **106.7×** | yes, 1,500 rows |

5 interleaved runs after one warm-up run per engine.

### The workbook's monthly query compared two different answers

The workbook uses `strftime(done_on, '%Y-%m')` for both engines. The two engines take the arguments in **opposite order**:

| Engine | Signature | `strftime(done_on, '%Y-%m')` gives |
|---|---|---|
| SQLite | `strftime(format, date)` | `NULL` |
| DuckDB | `strftime(date, format)` | `2026-01`, `2026-02`, ... |

With the workbook's version ([output](race-workbook-results.txt)), SQLite put all 2,000,000 rows into **50 groups with an empty month** while DuckDB returned **1,500** groups, and the "ratio" (about 65×) compared two different answers. My `race.py` uses each engine's own order and checks that both engines return identical rows before timing. With the correct SQLite query the monthly report got **slower** in SQLite (about 2,000 ms → 3,073 ms), because now it really formats a date on every row.

Lesson: the result check is not optional. The workbook says it for the sum in Round 2, and it applies to every query in the race.

- **What would make SQLite win?** A point query on an index, for example one machine or one day. A full aggregate over 2M rows cannot: SQLite has to read every full row. Round 5 measures the other side.

## Round 4: The plan

[plan.py](plan.py) · [output](plan-results.txt) (run with `PYTHONIOENCODING=utf-8` on Windows, because the plan is drawn with box characters)

DuckDB `EXPLAIN ANALYZE` for the dashboard aggregate, read bottom-up:

| Operator | Detail | Rows | Time |
|---|---|---|---|
| `TABLE_SCAN` (`READ_PARQUET`) | **Projections: `machine_id`, `site`, `technician`, `part_price`** (4 of 7 columns) | 2,000,000 | 0.08 s |
| `PROJECTION` | the same 4 columns | 2,000,000 | 0.00 s |
| `HASH_GROUP_BY` | Groups #0 #1 #2, Aggregates `sum(#3)` | **350** | **0.13 s** |

SQLite's `EXPLAIN QUERY PLAN`: `SCAN report_history` + `USE TEMP B-TREE FOR GROUP BY`, one pass over **full** rows (all 7 columns).

- **The line that proves the column store read less:** `Projections:` lists 4 columns. `job_id`, `part_no` and `done_on` were never read.
- **`SELECT *`:** the projections list all 7 columns, and the row count stays at 2,000,000.
- **Which operator dominates?** On my machine it was `HASH_GROUP_BY` (0.13 s) more than the scan (0.08 s), unlike the workbook's example. Both operators handle all 2M rows. These per-operator times add up the work of all threads, which is why they are larger than the 33 ms wall-clock time in the race.
- **Prediction vs. measurement:** SQLite's plan is a prediction (no timings); DuckDB's `EXPLAIN ANALYZE` runs the query and measures it. To explain a 75× gap to a manager, I would show the measurement.

## Round 5: The boundary

[boundary.py](boundary.py) · [output](boundary-results.txt)

**My prediction:** SQLite wins. **Correct**, by three orders of magnitude.

| 1,000 statements, median of 5 runs | SQLite | DuckDB | DuckDB slower by |
|---|---|---|---|
| inserts, one `execute` per row | 1.3 ms | 5,279.4 ms | ~4,000× |
| inserts, `executemany` | 0.7 ms | 4,910.8 ms | ~7,000× |
| lookups by primary key | 1.8 ms | 1,930.3 ms | ~1,000× |
| inserts, **one set-based `INSERT ... SELECT`** | | **2.2 ms** | |

- **"For Kortmann, DuckDB is the wrong engine when"** the work is many small statements, one row at a time, like recording each new job on the line or looking up one machine: 1,000 single-row inserts take about 5 seconds in DuckDB vs. about 1 ms in SQLite.
- **Why the per-statement cost dominates:** every statement is parsed, planned and run as its own small job, and DuckDB is built to spread one big job over many rows and threads. For one row, that set-up costs far more than the work.
- **`executemany`** barely helped DuckDB here (5,279 → 4,911 ms), less than the ~3× the workbook mentions: it still executes the insert once per row. What closes the gap is changing the **application** to send all rows as one set-based statement (2.2 ms).
- **My final project:** any part that records sensor readings or events one by one sits right at this boundary and belongs in SQLite.

## Round 6: Decide

[memo.md](memo.md): move **only the month-end report** (the two-year history) to Parquet + DuckDB, refreshed **every night** automatically; keep everything used constantly during the day (single-row writes and lookups, the dashboard) in SQLite.

## Section 7 (core homework): zstd copy

[zstd.py](zstd.py) · [output](zstd-results.txt)

| Compression | Size | Dashboard median (5 runs, warm) |
|---|---|---|
| snappy (default) | 2.40 MB | 29.6 ms |
| zstd | **1.39 MB** | 30.3 ms |

Same results, 42% smaller file, practically the same speed. A smaller file is the same speed while it fits in memory; once it does not, the smaller file wins. The refresh paragraph is in the [memo](memo.md).

Not done: the stretchers (S1-S3) and the intense track (`refresh.py`).
