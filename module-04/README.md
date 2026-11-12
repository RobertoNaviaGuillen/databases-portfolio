# Module 4: Data Integrity, Constraints & Edge Triggers

Course: Databases (HSBI) · Session 4 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/04-integrity-constraints-and-triggers.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Create tables with the full constraint toolkit: `NOT NULL`, `UNIQUE`, `CHECK`, `PRIMARY KEY`, `FOREIGN KEY`, and `STRICT` typing.
2. Use **generated columns** to derive values at the engine instead of in application code.
3. Write **triggers** that enforce domain rules and maintain audit/rollup tables automatically.
4. Use **DML** correctly, including `UPSERT` (`ON CONFLICT`) for idempotent edge ingestion.
5. Reason about **access control (DCL)**: who may read or write, and how that maps from server `GRANT`s to an embedded, local-first world.

## Tasks

- [x] Pod Study, Task A (acceptance test): [acceptance-test.sql](acceptance-test.sql), [output](acceptance-test-results.txt), notes in [integrity-notes.md](integrity-notes.md#task-a-the-acceptance-test)
- [x] Pod Study, Task B: discussed inside my pod (no other pod), compared with Erick, see [integrity-notes.md](integrity-notes.md#task-b-share-with-another-pod)
- [x] Setup: [setup.sql](setup.sql) builds `edge.db` (not committed; rebuild with the commands below)
- [x] Task 1: Prove the constraints work ([script](task1-constraints.sql), [output](task1-results.txt))
- [x] Task 2: Idempotent ingestion with UPSERT ([SQL](task2-upsert.sql), [output](task2-results.txt), [ingest.py](ingest.py), [double-run output](ingest-results.txt))
- [x] Task 3: Triggers for alarms and audit ([trigger DDL](triggers.sql), [exercise](task3-triggers.sql), [output](task3-results.txt), [cost benchmark](trigger_bench.py), [benchmark output](trigger-bench-results.txt))
- [x] Task 4: Access control without a server ([script](task4-access.sh), [output](task4-results.txt))
- [ ] Task 5 (Stretcher): not done
- [x] Reflection: [ref04.md](../Reflections/ref04.md)

### Rebuild everything

Run from the repo root (Git Bash):

```sh
rm -f module-04/edge.db
sqlite3 module-04/edge.db ".read module-04/setup.sql"
sqlite3 module-04/edge.db ".read module-04/task1-constraints.sql"
sqlite3 module-04/edge.db ".read module-04/task2-upsert.sql"
uv run python module-04/make_readings.py
uv run python module-04/ingest.py
sqlite3 module-04/edge.db ".read module-04/triggers.sql"
sqlite3 module-04/edge.db ".read module-04/task3-triggers.sql"
uv run python module-04/trigger_bench.py
sh module-04/task4-access.sh
```

## Task 1: Prove the constraints work

All four bad statements were rejected ([output](task1-results.txt)):

| Statement | Layer | Exact error |
|---|---|---|
| reading with value `9000` | semantic (`CHECK`) | `CHECK constraint failed: value >= -273.15 AND value <= 5000` |
| reading with value `'hot'` | semantic (`STRICT` type) | `cannot store TEXT value in REAL column reading.value` |
| reading for sensor `99` (does not exist) | referential | `FOREIGN KEY constraint failed` |
| second `temp_c` sensor on `cnc-01` | entity | `UNIQUE constraint failed: sensor.machine_id, sensor.metric` |

**Generated column:** the valid reading (`value` 41.5, `interval_s` 1) shows `energy_j = 41.5`. Nobody inserted that value; the engine computed it from `value * interval_s`.

**Extra:** with `PRAGMA foreign_keys = OFF` the same sensor-99 reading **was stored** as an orphan. Foreign keys are off by default and must be switched on in every connection; a tool that forgets it silently skips the check.

## Task 2: Idempotent edge ingestion with UPSERT

```sql
CREATE UNIQUE INDEX ux_reading_sensor_ts ON reading(sensor_id, ts);

INSERT INTO reading(sensor_id, ts, value, interval_s)
VALUES (1,'2026-03-01 08:00:00', 41.7, 1)
ON CONFLICT(sensor_id, ts) DO UPDATE SET value = excluded.value;
```

- With the unique index, a plain `INSERT` of the same reading fails (`UNIQUE constraint failed: reading.sensor_id, reading.ts`). The `UPSERT` instead updated the existing row: still **one** row for that key, value 41.5 → 41.7 ([output](task2-results.txt)).
- [ingest.py](ingest.py) reads `readings.csv` (1,000 readings made by [make_readings.py](make_readings.py), seed 42) and loads it with `executemany` and the same `UPSERT`, **twice** ([output](ingest-results.txt)):

| | after run 1 | after run 2 |
|---|---|---|
| `reading` with the natural key and `UPSERT` | 1,001 rows | **1,001 rows** (no duplicates) |
| table without a key, plain `INSERT` | 1,000 rows | **2,000 rows** (every row duplicated) |

(1,001 = the 1,000 CSV readings + the one valid reading from Task 1.)

## Task 3: Triggers for alarms and audit

Trigger DDL from the workbook: [triggers.sql](triggers.sql). Results ([output](task3-results.txt)):

- **Alarm:** a vibration reading of 2.7 mm/s on sensor 2 produced the `alarm` row `(1, sensor 2, 2026-03-01 09:00:00, 2.7, 'vibration over 2.0 mm/s')` without the writer doing anything.
- **Audit:** updating that value to 1.4 produced the `audit` row `(1, reading 1002, old 2.7, new 1.4, changed_at)`.
- A temperature of 55.0 raised **no** alarm: the trigger also checks that the sensor's metric is `vib_rms`.
- An `UPSERT` that changes a value (55.0 → 56.0) also fires the audit trigger, because it is an `UPDATE` under the hood.

> I changed one line of the workbook: it updates `WHERE sensor_id = 2`, but in my `edge.db` sensor 2 already holds the 500 readings from `ingest.py`, so I limited the `UPDATE` to the new reading (`AND ts = '2026-03-01 09:00:00'`). Otherwise 501 values would have been overwritten.

### Trigger cost

[trigger_bench.py](trigger_bench.py) ingests 10,000 readings (half temperature, half vibration) into a fresh in-memory copy of the schema, with and without `trg_vib_alarm`. One warm-up run each, then 15 alternating runs; median reported ([output](trigger-bench-results.txt)):

| | median time | alarms raised |
|---|---|---|
| without alarm trigger | 21.4 ms | 0 |
| with alarm trigger | 46.8 ms | 1,248 |

The trigger made the ingest about **2.2× slower** (+25 ms, about 2.5 µs per row). For every row it looks up the sensor's metric, and for 1,248 rows it also writes an alarm row. My first version without a warm-up run gave unstable numbers (between 3% and 100% slower), so a single run is not enough to measure this.

## Task 4: Access control without a server

Commands and outcomes ([script](task4-access.sh), [output](task4-results.txt)):

| Control | Command | Read | Write (`DELETE FROM reading`) |
|---|---|---|---|
| View for report readers | `CREATE VIEW machine_health AS SELECT machine_id, metric, MAX(value) AS peak, COUNT(*) AS n ...` | peak and count per machine/metric only | |
| File level | `chmod 444 module-04/edge.db` | works (1,003 rows) | `attempt to write a readonly database` |
| Connection level | `sqlite3 "file:module-04/edge.db?mode=ro"` | works (1,003 rows) | `attempt to write a readonly database` |
| Connection level | `PRAGMA query_only = ON` | | `attempt to write a readonly database` |

On Windows, Git Bash's `chmod 444` sets the file's read-only attribute (`attrib` shows `R`). Afterwards `chmod 644` restored write access and the count was still 1,003 rows: nothing was deleted.

**Comparison with a server.** With PostgreSQL, the server checks every request against named users and roles: I would `CREATE ROLE report_reader` and `GRANT SELECT ON machine_health TO report_reader`, and that user could never touch the `reading` table, whatever program they use. SQLite has no users, so whoever can open the file can do everything the operating system allows; read-only mode and views only help if the program opening the file chooses to use them. That is acceptable at the edge, where one gateway process on one box owns the file and the only "users" are the plant's own tools. It is not acceptable for a multi-tenant web app, where many customers share the same data and each may only see their own rows, because file permissions are all-or-nothing for the whole database and cannot tell one customer from another.

## Pod Study

Notes, the acceptance test and the follow-ups (`CHECK` with `NULL`, plausible but wrong values): [integrity-notes.md](integrity-notes.md).
