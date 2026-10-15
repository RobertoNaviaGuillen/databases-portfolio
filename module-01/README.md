# Module 1 — Introduction & Local-First Foundations

Course: Databases (HSBI) · Session 1

## Learning Goals

By the end of this module, I can:

1. Explain how this class works — the CBL/PBL philosophy, the portfolio-based **project work** assessment, and the "moving bar" of a first-time course.
2. Set up my personal GitHub portfolio from the course template, with a clean first commit and a `.gitignore` that keeps databases and secrets out of Git.
3. Set up the entire toolchain reproducibly with **`uv`** — one fixed Python plus SQLite, DuckDB, Datasette, and more — on Windows, macOS, or Linux, and verify it.
4. Explain — with a measurement, not a slide — the difference between an **embedded** database and a **client/server** database, and why most local apps should not run a server.
5. Load real rows into SQLite and query them from Python using **bound parameters**.
6. Take a first LLM-generated query, run it, and begin the habit that defines this course: **verify before you trust**.

**What I plan to explore:** how far a single SQLite file can go before a real server is needed, using the machine-shop telemetry from the Wittkamp story.

## Personal Profile

- **Programming experience / languages:** Python and C#. A decent amount of programming experience, but I'm rusty. I expect it to come back quickly once I start practicing again, and I learn fast.
- **Prior SQL / databases used:** None yet — this course is my first contact with SQL and databases.
- **Python / command line / Git:** Comfortable with all three.
- **Built a web app or run a server?** I have built some websites with the help of AI tools.
- **My expectations from this class:** To really learn databases and SQL, and to build a good final project.

## Task Pod

- Leviscus Njeru — https://github.com/leviscusgnjeru/databases.git
- Ian Okach — https://github.com/Okach81/Databases_ianportfolio

## Tasks

- [x] Task 1 — Portfolio created from template, `.gitignore`, learning goals
- [ ] Task 2 — Git & Markdown proficiency in the pod
- [x] Task 3 — Toolchain with `uv` ([check script](../uv-check.py), [output](uv-check-output.txt), [pyproject.toml](../pyproject.toml), [uv.lock](../uv.lock))
- [x] Task 4 — `sqlite3` shell tour ([commands](tour-commands.sql), [captured session](shell-tour.txt), [dump](tour.sql))
  - Ran with `sqlite3 module-01/tour.db < module-01/tour-commands.sql` to avoid the bracketed-paste problem on Windows. `tour.db` itself is not committed (ignored by `.gitignore`) — it can be rebuilt from `tour.sql`.
  - **Most useful dot-command:** `.dump`, because it turns the whole database (schema + data) into plain SQL text that can be committed to Git and used to rebuild the database anywhere.
- [x] Task 5 — SQL Island ([answers + screenshot](sql-island.md)) — to be finished at home
- [x] Task 6 — Load telemetry and query it
  - Scripts: [generate_telemetry.py](generate_telemetry.py) → `telemetry.csv` (7.8 MB), [load_telemetry.py](load_telemetry.py) → `telemetry.db` (CSV → SQLite using bound parameters `?`)
  - Queries: [queries.sql](queries.sql) · Results with timings: [query-results.txt](query-results.txt)
  - **`telemetry.db`: 11 MB, 172,800 rows** ([db-size.txt](db-size.txt)) — not committed; rebuild with the two scripts.

    | Question | Result | Time |
    |---|---|---|
    | Readings per machine | 57,600 each (cnc-01, cnc-02, cnc-03) | 0.067 s |
    | Peak vibration | cnc-01: 2.398 · **cnc-02: 3.168** · cnc-03: 2.55 | 0.078 s |
    | Readings above the 2.0 mm/s alarm | 11,714 | 0.016 s |

    cnc-02 has the highest peak — that is the bearing wear built into the generator.
  - **Cloud cost:** 11 MB for two days is roughly 2 GB a year — a cloud setup (server + managed PostgreSQL + backend) would cost tens of euros every month, paid by Wittkamp, for data that one laptop answers in under 0.1 s with zero infrastructure.
- [ ] Task 7 — LLM-assisted SQL profiling

## Reflection

[Reflection 1](../Reflections/ref01.md)
