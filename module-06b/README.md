# Module 6b: Polyglot Persistence & the Decision

Course: Databases (HSBI) · Session 7 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/06b-polyglot-persistence.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Store **semi-structured data (JSON)** in SQLite and query it with `json_extract`/`json_each` and an **expression index**.
2. Implement and evaluate a **key-value access pattern** against SQLite.
3. Explain **ACID vs. BASE** and the **CAP theorem** in terms of the systems I actually ran.
4. Choose an engine per workload and **defend the choice with a measurement**.
5. Say what changes, and what gets harder, when the same data lives on a **server**.

## Tasks

- [x] Task 1: The boundary, shared PostgreSQL server ([section](#task-1-the-boundary-shared-postgresql-server), [screenshots](pictures/)) + SQLite two-writer comparison ([two_writers.py](two_writers.py), [output](two-writers-results.txt))
- [x] Task 2: The shape, JSON column ([json_bench.py](json_bench.py), [output](json-bench-results.txt)) and key-value comparison ([kv_compare.py](kv_compare.py), [output](kv-compare-results.txt))
- [x] Task 3: The decision record ([decision-record.md](decision-record.md)), defence with Pod 2 (recorded by Leviscus) and one revised row
- [ ] Project ticket
- [x] Reflection: [ref06b.md](../Reflections/ref06b.md)

## Task 1: The boundary (shared PostgreSQL server)

**When:** the server exercise took place in class on 19 November 2026. I ran my own session on the same `pod16` database on **25 November 2026**, through pgweb at `hsbi-dbs.ulno.net` (two browsers: Chrome and Edge). The class credentials are not stored in this repo.

### What I ran

| # | Query | Result | Screenshot |
|---|---|---|---|
| 1 | `SELECT current_user;` | `pod16` (login worked) | [pg-01](pictures/pg-01-current-user.png) |
| 2 | `SELECT * FROM machine;` | 6 rows: my pod mates had already added machines 2, 3, 5, 16, 20, and machine 1 had grown from 0 to 18 | [pg-02](pictures/pg-02-select-machine.png) |
| 3 | `SELECT tableowner FROM pg_tables WHERE tablename = 'machine';` | `pod16` | [pg-03](pictures/pg-03-table-owner.png) |
| 4 | `has_table_privilege(...)` for SELECT, INSERT, UPDATE | `true`, `true`, `true` | [pg-04](pictures/pg-04-privileges.png) |
| 5 | `INSERT INTO machine(site) VALUES ('herford');` | `ERROR: null value in column "machine_id" of relation "machine" violates not-null constraint` | [pg-05](pictures/pg-05-insert-without-id.png) |
| 6 | `INSERT INTO machine VALUES (7, 'herford', 0);` | inserted; 7 rows afterwards | [pg-06](pictures/pg-06-insert-machine-7.png), [pg-07](pictures/pg-07-after-insert.png) |

Query 5 is the DDL difference the workbook mentions: in SQLite an `INTEGER PRIMARY KEY` numbers itself, in PostgreSQL it does not, so the same `INSERT` fails. Same SQL, different engine, different behaviour (like `strftime` in [Module 6a](../module-06a/duckdb-notes.md#the-workbooks-monthly-query-compared-two-different-answers)).

### Two writers, one row

| Browser | Statement | Run time |
|---|---|---|
| Chrome (writer 1) | `BEGIN; UPDATE machine SET parts_produced = parts_produced + 1 WHERE machine_id = 7; SELECT pg_sleep(20); COMMIT;` | 20,027 ms ([pg-08](pictures/pg-08-writer1-lock-20s.png)) |
| Edge (writer 2), started about 8 s later | `UPDATE machine SET parts_produced = parts_produced + 1 WHERE machine_id = 7;` | **12,205 ms**, 1 row affected ([pg-09](pictures/pg-09-writer2-waited.png)) |

Final value of machine 7: **2** ([pg-10](pictures/pg-10-result-machine-7.png)). Writer 2 **waited** for exactly the time writer 1 still held the row lock, then ran. No update was lost, because the database did the arithmetic (`parts_produced + 1`).

**SQLite comparison** ([two_writers.py](two_writers.py), [output](two-writers-results.txt)): while connection A holds `BEGIN IMMEDIATE`, connection B gets `database is locked` (with no wait time set). SQLite locks the **whole database file** for writing; PostgreSQL locked only **one row** and made the second writer wait. The same script also shows a **lost update** that neither engine prevents: if both clients read 2, add 1 in Python and write back 3, one change is lost (expected 4, got 3).

### Losing the server

I did not record the outage myself. My pod mate Leviscus captured it during the class on 19 November ([his evidence](https://github.com/leviscusgnjeru/databases/blob/main/Module06b/evidence/README.md)): the same `SELECT` succeeded at 10:35, failed at 10:57 with `dial tcp 127.0.0.1:5432: connect: connection refused` while the pgweb page itself stayed up, and succeeded again at 10:58 after the restart.

### Three observations, compared with my pod

| | Me | [Leviscus](https://github.com/leviscusgnjeru/databases/blob/main/Module06b/README.md) | [Erick](https://github.com/ErickLiebisch/databases-portfolio/blob/main/Module06b/README.md) | [Ian](https://github.com/Okach81/Databases_ianportfolio/blob/main/Module06b/polygot-notes.md) |
|---|---|---|---|---|
| **Easier** | The whole pod reads and edits the same data from any computer: 6 machines from my pod mates were already there | Same: rows inserted and updated by others became visible in later queries | Same: rows from teammates appeared immediately, "no files passed around" | Same: other users had already inserted machines |
| **Harder** | Users, passwords and permissions per table; logging in is not the same as being allowed to read (authentication vs. authorization); `INTEGER PRIMARY KEY` does not number itself | **The permission error happened to him in class:** connected as `pod16`, but `permission denied for table machine` and `false` for SELECT/INSERT/UPDATE until the professor fixed the grants | Access: URL, basic auth, host, port, database, user, password and SSL mode, versus only a file path for SQLite; credentials become a secret to keep out of a public repo | (not written) |
| **New failure mode** | If the server goes down, every client loses the data at once and no SQL can fix it; a SQLite file is on my own laptop | Observed it: `connection refused` during the stop, recovered after the restart | Single point of failure: "it cannot be switched off for me by someone else" with an embedded file | (not written) |
| **Two writers** | Writer 2 waited 12.2 s; final value 2 | He and Chanbopha both experienced waiting; no exact times | Writer 2 waited about 97 s until writer 1 committed; final value 2; uncommitted change invisible to the other browser | Two sessions added 10 and 5 to one row; final 15, no lost update |

**What we agree on:** a server makes **sharing** easy (one live copy for the whole pod) and makes **access** harder (credentials, roles, grants), and it adds a failure mode an embedded database does not have: **one server down = everyone down**. All of us who tested two writers saw that PostgreSQL serializes conflicting updates to one row without losing either.

**What the others added that I did not see myself:** Leviscus experienced the permission error that the professor's slide was about (authentication worked, authorization failed). Erick saw **isolation** directly: the other browser still read 0 while the first transaction was not committed, and a failed statement left his session "aborted" until `ROLLBACK`, which is atomicity in action.

## Task 2: The shape (JSON and key-value)

### JSON column in SQLite

[json_bench.py](json_bench.py) · [output](json-bench-results.txt)

- `CHECK (json_valid(meta))` makes the column a guaranteed JSON document: `'vendor=Siemens'` was rejected with `CHECK constraint failed: json_valid(meta)` (the Module 4 constraint idea, applied to a flexible column).
- A new vendor field needs no migration: a laser with a new key `laser_kw` was inserted and queried right away.
- `json_each` turns one document into rows (`vendor`, `firmware`, `calibrated` for `cnc-01`).

| Query | Plan |
|---|---|
| `WHERE json_extract(meta, '$.vendor') = 'Fanuc'` | `SEARCH device USING INDEX ix_device_vendor (<expr>=?)` |
| `WHERE meta ->> 'vendor' = 'Fanuc'` | `SCAN device` |

Both return the same 334 rows. **Why `->>` loses the index:** the expression index stores the result of exactly `json_extract(meta, '$.vendor')`, and SQLite only uses it when the query contains that same expression; `meta ->> 'vendor'` gives the same values but is a different expression, so SQLite reads every row.

### Key-value comparison (session state)

[kv_compare.py](kv_compare.py) · [output](kv-compare-results.txt) · 20,000 sessions, 3 runs (orders of magnitude, as the workbook asks)

| | set 20,000 | get 20,000 |
|---|---|---|
| `shelve` (key-value) | **77 to 107 s** | ~0.2 s |
| SQLite | **0.07 to 0.18 s** | ~1.7 s |

- **Writing:** SQLite was about **1,000× faster**. **Reading:** `shelve` was about **8× faster**.
- **Why `shelve` was so slow to write here:** on Python 3.14, `shelve`'s default backend is `dbm.sqlite3` (checked with `dbm.whichdb`). The "key-value store" is a SQLite file with one table (`Dict`), and every `db[key] = value` is committed on its own: 20,000 separate commits to disk. The SQLite side uses one `executemany` and one commit. Erick found the same backend ([his notes](https://github.com/ErickLiebisch/databases-portfolio/blob/main/Module06b/README.md)), but his `shelve` writes were much faster (5.3 s for 50,000), so the slow commits are probably specific to my machine or to this folder being synced by OneDrive. Same lesson as Modules 4 and 6a: many small operations one by one are what is expensive.
- **One thing SQLite can do that `shelve` cannot:** a query **across** sessions. `GROUP BY` on the filter gave 5,000 sessions per city filter in one query; `shelve` can only look up one key at a time.
