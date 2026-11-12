# Module 6a: Memo to Lea Winter and Yasmin Kaya

Back to [Module 6a](README.md) · Numbers from [duckdb-notes.md](duckdb-notes.md)

**To:** Lea Winter (controlling), Yasmin Kaya (operations lead)
**From:** Roberto Navia Guillen
**Subject:** Moving the month-end report out of the operational database

I recommend moving **only the month-end report** (the two-year history) to a Parquet file that DuckDB reads, and keeping everything else, including the dashboard, in SQLite. On our 2,000,000-row test history, the monthly report took a median of **3,073 ms in SQLite and 29 ms in DuckDB (107×)**, and the dashboard-style aggregate **2,480 ms vs. 33 ms (75×)**, with identical results checked row by row before timing. The Parquet file is **2.4 MB** (1.4 MB with zstd compression, same speed) against **112.7 MB** for the SQLite history, and reading it never blocks the writer on the line. I would never move anything that is used constantly, many times a day, one row at a time: writing each new job and looking up a single machine. There DuckDB is the wrong engine: 1,000 single-row inserts took **5,279 ms in DuckDB vs. 1.3 ms in SQLite**, and 1,000 primary-key lookups **1,930 ms vs. 1.8 ms**. Batching with `executemany` did not close the gap (4,911 ms); only rewriting the load as one set-based `INSERT` did (2.2 ms), which is a change to the application, not the engine.

**Refresh.** The Parquet copy is rebuilt **automatically every night** by a scheduled job that runs the `COPY` from [to_parquet.py](to_parquet.py) after the last shift, and then compares the row count and `SUM(part_price)` of SQLite and Parquet; it may only replace yesterday's file if both numbers match. If the refresh silently stopped, the report would still run fast but on old data: the month-end numbers would miss the latest jobs, and nobody would notice from the speed alone. To detect that, the report should print the newest `done_on` date in the file next to its results, so Lea can see at once whether the copy is from last night. For a month-end report, a copy that is at most one day old is acceptable; a report that blocks the line for 40 minutes is not.
