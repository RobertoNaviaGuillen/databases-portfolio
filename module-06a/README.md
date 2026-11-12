# Module 6a: The Analytical Engine (DuckDB)

Course: Databases (HSBI) · Session 6 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/06a-duckdb-analytical-engine.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Move a table out of SQLite into **Parquet** reproducibly, from a script.
2. Run the **same aggregate** in SQLite and DuckDB and report the difference honestly (interleaved runs, median).
3. Read **`EXPLAIN ANALYZE`** and name the operator and row count that dominate.
4. State, with a number, **where DuckDB is the wrong engine**.
5. Recommend **what moves to the analytical copy** and how that copy stays fresh.

## Rounds

All numbers and explanations are in [duckdb-notes.md](duckdb-notes.md).

- [x] 1 · Build: 2,000,000-row history ([prepare.py](prepare.py), [output](prepare-results.txt))
- [x] 2 · Convert: Parquet + matching row count, sum and dates ([to_parquet.py](to_parquet.py), [output](to-parquet-results.txt))
- [x] 3 · Race: timing table for two queries ([race.py](race.py), [output](race-results.txt), [workbook version](race-workbook-results.txt))
- [x] 4 · Plan: `EXPLAIN ANALYZE` ([plan.py](plan.py), [output](plan-results.txt))
- [x] 5 · Boundary: inserts and lookups in both engines ([boundary.py](boundary.py), [output](boundary-results.txt))
- [x] 6 · Decide: [memo.md](memo.md)
- [x] 7 · Core homework: zstd copy and refresh paragraph ([zstd.py](zstd.py), [output](zstd-results.txt))
- [ ] Stretchers S1-S3, intense track (`refresh.py`): not done
- [ ] Reflection: [ref06a.md](../Reflections/ref06a.md)

### Rebuild everything

Run from the repo root. Needs `module-05/normalize.db` (see [Module 5](../module-05/README.md#rebuild-everything)). `history.db`, the CSV and the Parquet files are not committed.

```sh
uv run python module-06a/prepare.py
uv run python module-06a/to_parquet.py
uv run python module-06a/race.py
PYTHONIOENCODING=utf-8 uv run python module-06a/plan.py
uv run python module-06a/boundary.py
uv run python module-06a/zstd.py
```

## Results at a glance

| | SQLite | DuckDB + Parquet |
|---|---|---|
| Storage of the 2M-row history | 112.65 MB | 2.40 MB (1.39 MB zstd) |
| Dashboard aggregate (median) | 2,480 ms | 33 ms (**75×**) |
| Monthly report (median) | 3,073 ms | 29 ms (**107×**) |
| 1,000 single-row inserts | **1.3 ms** | 5,279 ms |
| 1,000 primary-key lookups | **1.8 ms** | 1,930 ms |

- **Finding:** the workbook's monthly query uses `strftime(done_on, '%Y-%m')` in both engines, but SQLite's argument order is `strftime(format, date)`, so SQLite returned `NULL` months (50 groups vs. DuckDB's 1,500). My race uses each engine's own order and checks identical results before timing ([details](duckdb-notes.md#the-workbooks-monthly-query-compared-two-different-answers)).
- **Decision** ([memo](memo.md)): only the month-end report moves to Parquet, rebuilt nightly with a row-count and sum check; everything used constantly during the day stays in SQLite.
