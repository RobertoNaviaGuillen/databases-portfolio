# Module 6b: Decision record for Kortmann

Back to [Module 6b](README.md)

**Author:** Roberto Navia Guillen · **Date:** 25 November 2026 · Every row cites a measurement or observation from this course.

| Workload | Engine | Why | Evidence | Cost accepted | What breaks if stale/missing? |
|---|---|---|---|---|---|
| **Month-end report over two years** | Parquet + DuckDB | A full aggregate over 2M rows is about 100× faster than in the operational SQLite, and reading a file never blocks the writer | [6a](../module-06a/duckdb-notes.md): monthly report 3,073 ms → 29 ms (107×), dashboard aggregate 2,480 → 33 ms (75×), identical results checked; Parquet 2.4 MB (1.4 MB zstd) vs. 112.7 MB | A nightly rebuild with a row-count and sum check; the copy can be up to one day old | The report runs on yesterday's data; it shows the newest date in the file, so a stale copy is visible |
| **Sensor/job ingest, every 30 s, crash must not lose rows** | SQLite | Embedded, one writer on the gateway, no network or server that can be down; single-row writes are what SQLite is fast at | [Module 4](../module-04/README.md): `UPSERT` on `(sensor_id, ts)`, loading the same 1,000 readings twice gave 1,001 rows, not 2,000; `CHECK`/`STRICT`/`FOREIGN KEY` rejected impossible values; [6a](../module-06a/duckdb-notes.md#round-5-the-boundary): 1,000 single-row inserts 1.3 ms in SQLite vs. 5,279 ms in DuckDB | One writer at a time; the alarm trigger made a 10,000-row ingest about 2.2× slower | Missing rows are re-sent by the gateway and the `UPSERT` absorbs replays without duplicates; a commit survives a crash (durability) |
| **Vendor metadata that gains fields** | SQLite, JSON column | New vendor fields need no migration, and the document stays next to the relational `machine` row, so joins stay cheap | [Task 2](README.md#json-column-in-sqlite): `CHECK (json_valid(meta))` rejected non-JSON; a new key `laser_kw` needed no `ALTER TABLE`; expression index: `json_extract(meta, '$.vendor')` → `SEARCH ... USING INDEX`, `meta ->> 'vendor'` → `SCAN` | No column-level types inside the JSON; the index only works for the exact expression it was built on | A missing key just returns `NULL` (for example no calibration date), so queries must handle absent fields |
| **Dashboard session state** | Key-value (`shelve`) | A session is read by one key and nothing else; reading was the faster side | [Task 2](README.md#key-value-comparison-session-state), 20,000 sessions, 3 runs: get ~0.2 s in `shelve` vs. ~1.7 s in SQLite (about 8× faster); set 77 to 107 s in `shelve` vs. 0.07 to 0.18 s in SQLite | Writes were about 1,000× slower on my machine (every set is its own commit; on Python 3.14 `shelve` is itself SQLite underneath); no queries across sessions | A lost session only logs a user out or resets their last filter; no plant data is lost |
| *(optional)* **Concurrent users on the network** | SQLite (stay embedded) | The plant has few writers; a server adds credentials, operations and a single point of failure | [Task 1](README.md#two-writers-one-row): PostgreSQL made the second writer wait 12.2 s for a row lock, no lost update; SQLite returned `database is locked` for the second writer ([output](two-writers-results.txt)); Leviscus recorded the server outage (`connection refused`) | SQLite locks the whole file for writing, so writers queue; if many people write at once, they will see `database is locked` | If writers start colliding often, that is the measured requirement to move this workload to PostgreSQL |

## If Kortmann could run only one engine

**SQLite**, because it already serves four of the five workloads (ingest, vendor metadata, concurrent users, and even the session store, since `shelve` on Python 3.14 is SQLite underneath). **The first thing to break would be the month-end report:** 3,073 ms instead of 29 ms on our 2M rows, and on the real two-year data the story's 40 minutes, during which the single writer on the line has to wait. The second thing would be many simultaneous writers over the network, where SQLite locks the whole database and PostgreSQL only one row.

## ACID, BASE and CAP in the systems I ran

- **ACID** was visible in both engines: the `UPSERT` and the triggers in Module 4 ran as one transaction (all or nothing); the second PostgreSQL writer could not change machine 7 until the first transaction committed (isolation), and Erick saw an uncommitted change stay invisible to the other browser; `CHECK` constraints kept the data consistent.
- **BASE** (basically available, eventually consistent) describes the nightly Parquet copy: the report is always available but may be up to one day behind, and it catches up at the next rebuild.
- **CAP** only applies when data is distributed over a network. SQLite and DuckDB run on one machine, so there is no partition. Our PostgreSQL server was a single server: when it stopped, every client lost access (no availability), but nobody received wrong data (consistency kept).

## Defence with another pod

_Not done yet._ The workbook asks to swap records with another pod and let them ask the four questions below. Until that happens, these are my prepared answers:

| Question | My answer |
|---|---|
| Which row has no measurement behind it? | None: every row cites my own numbers. The weakest is the concurrent-users row, because the plant's real number of writers is not measured. |
| Where does your choice duplicate data, and who updates it? | The Parquet file copies the history; the nightly job rebuilds it and checks rows and sum before replacing it. |
| What breaks if two people write at the same time? | In SQLite the second writer waits or gets `database is locked`; in PostgreSQL it waits for the row lock. Neither prevents a lost update if the application reads, adds and writes back by itself; the database must do the arithmetic. |
| Why is this a database and not three spreadsheets? | Constraints reject impossible values, `UPSERT` prevents duplicates, transactions keep half-done work invisible, and one query can answer questions across all rows. |

**Row changed after the defence:** _pending (after the defence)._
