# Module 1: Introduction & Local-First Foundations

Course: Databases (HSBI) · Session 1 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/01-introduction-and-local-first.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Explain how this class works: the CBL/PBL philosophy, the portfolio-based **project work** assessment, and the "moving bar" of a first-time course.
2. Set up my personal GitHub portfolio from the course template, with a clean first commit and a `.gitignore` that keeps databases and secrets out of Git.
3. Set up the entire toolchain reproducibly with **`uv`** (one fixed Python plus SQLite, DuckDB, Datasette, and more) on Windows, macOS, or Linux, and verify it.
4. Explain, with a measurement and not a slide, the difference between an **embedded** database and a **client/server** database, and why most local apps should not run a server.
5. Load real rows into SQLite and query them from Python using **bound parameters**.
6. Take a first LLM-generated query, run it, and begin the habit that defines this course: **verify before you trust**.

**What I plan to explore:** how far a single SQLite file can go before a real server is needed, using the machine-shop telemetry from the Wittkamp story.

## Personal Profile

- **Programming experience / languages:** Python and C#. A decent amount of programming experience, but I'm rusty. I expect it to come back quickly once I start practicing again, and I learn fast.
- **Prior SQL / databases used:** None yet. This course is my first contact with SQL and databases.
- **Python / command line / Git:** Comfortable with all three.
- **Built a web app or run a server?** I have built some websites with the help of AI tools.
- **My expectations from this class:** To really learn databases and SQL, and to build a good final project.

## Task Pod

- Leviscus Njeru: [portfolio](https://github.com/leviscusgnjeru/databases)
- Ian Okach: [portfolio](https://github.com/Okach81/Databases_ianportfolio)
- Chanbopha Rin: [GitHub profile](https://github.com/chanbopharin)

I joined this pod on 15 October 2026.

**Audit of Leviscus Njeru's portfolio:** He documented Module 1 learning goals, his profile and SQL Island (`SELECT`, `WHERE`, `AND`/`OR`, `LIKE`, `IS NULL`, `UPDATE`) with a screenshot and an honest reflection on the environment setup; Tasks 3 (Python 3.14 + `uv` check), 4, 6 and 7 are still pending, and his main README is still the IoT template. His `.gitignore` also covers `*.db-wal`/`*.db-shm`, which I had missed, so I added them to mine.

## Tasks

- [x] Task 1: Portfolio created from template, `.gitignore`, learning goals
- [x] Task 2: Git & Markdown proficiency in the pod (small commits, interlinks to the course and to my pod mates, [audit of Leviscus's portfolio](#task-pod))
- [x] Task 3: Toolchain with `uv` ([check script](../uv-check.py), [output](uv-check-output.txt), [pyproject.toml](../pyproject.toml), [uv.lock](../uv.lock))
- [x] Task 4: `sqlite3` shell tour ([commands](tour-commands.sql), [captured session](shell-tour.txt), [dump](tour.sql))
  - Ran with `sqlite3 module-01/tour.db < module-01/tour-commands.sql` to avoid the bracketed-paste problem on Windows. `tour.db` itself is not committed (ignored by `.gitignore`); it can be rebuilt from `tour.sql`.
  - **Most useful dot-command:** `.dump`, because it turns the whole database (schema + data) into plain SQL text that can be committed to Git and used to rebuild the database anywhere.
- [x] Task 5: SQL Island ([answers + screenshot](sql-island.md)), to be finished at home
- [x] Task 6: Load telemetry and query it
  - Scripts: [generate_telemetry.py](generate_telemetry.py) → `telemetry.csv` (7.8 MB), [load_telemetry.py](load_telemetry.py) → `telemetry.db` (CSV → SQLite using bound parameters `?`)
  - Queries: [queries.sql](queries.sql) · Results with timings: [query-results.txt](query-results.txt)
  - **`telemetry.db`: 11 MB, 172,800 rows** ([db-size.txt](db-size.txt)), not committed; rebuild with the two scripts.

    | Question | Result | Time |
    |---|---|---|
    | Readings per machine | 57,600 each (cnc-01, cnc-02, cnc-03) | 0.067 s |
    | Peak vibration | cnc-01: 2.398 · **cnc-02: 3.168** · cnc-03: 2.55 | 0.078 s |
    | Readings above the 2.0 mm/s alarm | 11,714 | 0.016 s |

    cnc-02 has the highest peak: that is the bearing wear built into the generator.
  - **Cloud cost:** 11 MB for two days is roughly 2 GB a year. A cloud setup (server + managed PostgreSQL + backend) would cost tens of euros every month, paid by Wittkamp, for data that one laptop answers in under 0.1 s with zero infrastructure.
- [x] Task 7: LLM-assisted SQL profiling ([all queries](llm-query.sql), [full output](llm-query-results.txt))

### Task 7: Verifying an LLM-generated query

**LLM used:** Claude (Anthropic). **Prompt:**

> Here is my SQLite table: `readings(ts TEXT, machine TEXT, temp_c REAL, vib_rms REAL, spindle_load REAL)`. Write a query that returns, for each machine, the average spindle load for readings taken overnight (after 18:00), ordered by average load descending.

**Generated SQL:**

```sql
SELECT machine, AVG(spindle_load) AS avg_load
FROM readings
WHERE time(ts) >= '18:00:00'
GROUP BY machine
ORDER BY avg_load DESC;
```

**Run it:** it executes (0.047 s) → cnc-03 60.43 · cnc-01 60.37 · cnc-02 60.36. Sanity check: 43,200 rows match, which is exactly 6 h × 1,200 readings/h × 2 days × 3 machines.

**Profile it (`EXPLAIN QUERY PLAN`):**

```
|--SCAN readings
|--USE TEMP B-TREE FOR GROUP BY
`--USE TEMP B-TREE FOR ORDER BY
```

`SCAN readings` = a full-table scan of all 172,800 rows. An index would not help here anyway, because `time(ts)` is a function applied to every row.

**Break it:**

| Variant | What it really means | Result |
|---|---|---|
| `ts > '2026-01-05 18:00:00'` | everything after Monday 18:00, **including Tuesday daytime** | cnc-02 on top, different answer |
| `ts LIKE '%18%'` | any timestamp containing "18" (minutes, seconds…) | 18,102 rows instead of 43,200, wrong |
| `time(ts) >= '18:00' OR time(ts) < '06:00'` | "overnight" read as 18:00-06:00 | cnc-02 on top, different answer |

**Verification paragraph:** The model got the syntax, the `GROUP BY` and the ordering right, and it correctly used `time(ts)` to compare only the time of day instead of comparing `ts` as a full date string. What it got "wrong" is a silent assumption: it read *overnight (after 18:00)* as 18:00-midnight only, while a night shift would also include 00:00-06:00, and with that reading the ranking flips (cnc-02 becomes first instead of last). I verified it by running it on the real data, checking the row count against a hand calculation (43,200), profiling it with `EXPLAIN QUERY PLAN` (full scan), and running the alternative versions side by side. Lesson: the averages differ by only ~0.1, so the "ranking" is mostly noise. A query can run perfectly and still answer a different question than the one the user meant.

## Reflection

[Reflection 1](../Reflections/ref01.md)
