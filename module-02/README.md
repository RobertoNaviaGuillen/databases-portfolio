# Module 2: Data Contracts & Reading Legacy Schemas (ERD Audits)

Course: Databases (HSBI) · Session 2 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/02-data-contracts-and-legacy-schemas.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Reconstruct an **ER/EER model** (entities, attributes, keys, relationships, cardinalities) from an undocumented SQL schema.
2. Identify **integrity defects** (missing foreign keys, orphan rows, redundant data, normalization violations) with queries, not intuition.
3. Distinguish an **entity relationship** from an attribute, and a **surrogate key** from a natural key, and justify the choice.
4. Express a schema as a **code-first data contract** (Pydantic / SQLAlchemy) that an application can enforce.
5. Write the **requirements the schema forgot**: the business rules nobody encoded.

## Tasks

- [ ] Pod Study, Tasks A-B (study log, four sketches): to do.
- [x] Pod Study, Task C (share with another pod): EER overlap example, documented in [study-log.md](study-log.md#task-c-explain--share-with-another-pod).
- [x] Setup: [legacy-setup.sql](legacy-setup.sql) builds `legacy.db` (not committed; rebuild with `sqlite3 module-02/legacy.db ".read module-02/legacy-setup.sql"`).
- [x] Task 1: Reconstruct the ER model: [er-audit.md](er-audit.md) (entities, Mermaid ER diagram, cardinalities proved with [counts](cardinality.sql), [output](cardinality-results.txt))
- [x] Task 2: Integrity defects proved with queries: [defects.sql](defects.sql), [output](defects-results.txt)
- [x] Task 3: Data contract: [contract.py](contract.py), emitted DDL [contract-ddl.sql](contract-ddl.sql), and a check that throws the legacy defects at it: [contract_check.py](contract_check.py), [output](contract-check-results.txt)
- [ ] Task 4 (Stretcher): inheritance
- [ ] Task 5 (Stretcher): Mermaid lab

## Before the queries: what I spotted by eye

Looking at the three tables, I found `installed = 'unknown'` (not a date), the duplicated part `P-1003`, and the suspicious `RANDOM-NAME` machine. I missed the orphan job on `cnc-05`, the comma-separated `parts_used` list, and that `unit_price` is text; the queries below found those.

## Task 2: Integrity defects, proved

| # | Defect | Query result | What breaks in production |
|---|---|---|---|
| 1 | **Orphan job**: `maint_job.machine_name` is text, not a foreign key | job 3 on `cnc-05`, a machine that does not exist | the job cannot be attributed to a site or a machine, so its cost and downtime are lost |
| 2 | **Duplicate natural key**: `part_no` is not `UNIQUE` | `P-1003` exists 2 times | every report that joins parts counts P-1003 jobs twice (see defect 5) |
| 3 | **Price stored as text** | `unit_price < '15'` returns only P-1001; the numeric comparison returns P-1001 **and** P-1003 (9.90) | text ordering (`'9.90' > '15'`) silently drops cheap parts: wrong cost reports and invoices |
| 4 | **Date stored as free text** | `RANDOM-NAME` has `installed = 'unknown'` | machine age and maintenance intervals cannot be calculated |
| 5 | **m:n list in one column** (violates 1NF) | the naive join returns job 2 **twice** and job 3, and **job 1 (`P-1001,P-1002`) silently disappears** | Anke's question ("which parts did we replace, how often?") is answered wrong without any error: one job missing, another double-counted |

Defects 2 and 5 multiply each other: the duplicate P-1003 row doubles job 2 in the join.

## Task 3: The data contract

[contract.py](contract.py) builds the repaired schema: `machine` with a surrogate key and `UNIQUE(serial_no)`, `part` with `part_no` as primary key and a `NUMERIC` price, `maint_job` with a real `FOREIGN KEY` to `machine`, and the junction table `job_part (job_id, part_no)` that replaces the comma list ([emitted DDL](contract-ddl.sql)).

**Which guard catches what** ([contract_check.py](contract_check.py) throws the legacy defects at both guards, with `PRAGMA foreign_keys = ON`):

| Bad data | Pydantic (application) | Database (DDL) |
|---|---|---|
| Job on a machine that does not exist | accepted | **rejected** (`FOREIGN KEY constraint failed`) |
| Duplicate part `P-1003` | n/a | **rejected** (`UNIQUE constraint failed`) |
| Price `'48.00'` as text | n/a | **converted** to a number by the `NUMERIC` column; "under 15" now returns P-1001 and P-1003 |
| `installed = 'unknown'` | **rejected** (not a valid date) | accepted (SQLite's flexible typing stores the text in a `DATE` column) |
| Two parts in one job | n/a | stored as two `job_part` rows; the join returns both parts |
| Same part listed twice in a job / a part that does not exist | n/a | **rejected** (`UNIQUE` / `FOREIGN KEY`) |
| Serial number without `SN-` | **rejected** (validator) | accepted |
| Repeated serial number | n/a | **rejected** (`UNIQUE`) |

**Model vs. database: my choice.**
- **In the database:** everything that needs to look at *other rows*: foreign keys (does the machine exist?), primary keys and `UNIQUE` (is this part or serial number already there?). Only the database sees all the data, and it protects it no matter which program writes to it.
- **In the model (Pydantic):** format and business rules on *one value*: a real date, the `SN-` prefix. They give a clear error message before anything is written, and SQLite would accept a wrong date silently.
- **Both are needed.** Neither guard caught every defect. Also, SQLite only enforces foreign keys after `PRAGMA foreign_keys = ON`.
- **What the workbook's contract still leaves out:** `technician` is still free text; in the ER model it is its own entity (`TECHNICIAN`), so a typo like "Beir" would still create a "new" technician.

## Requirements the schema forgot (business rules)

1. Every maintenance job happens on a machine that exists.
2. A part number identifies exactly one part.
3. A price is a positive amount of money, not text.
4. An installation date is a real date (or explicitly unknown with `NULL`, not the word `'unknown'`).
5. A job can use many parts and a part can be used in many jobs; each part is listed once per job.
6. Every machine has exactly one serial number, starting with `SN-`, and no two machines share one.
7. A technician is a known person, not a free-text name.
