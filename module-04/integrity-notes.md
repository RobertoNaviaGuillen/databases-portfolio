# Module 4: Integrity notes

Back to [Module 4](README.md)

## Integrity has three layers

| Layer | Question it answers | SQL mechanism | Example error from my runs |
|---|---|---|---|
| **Entity** | Is every row identifiable and complete? | `PRIMARY KEY`, `NOT NULL`, `UNIQUE` | `UNIQUE constraint failed: sensor.machine_id, sensor.metric` |
| **Referential** | Do relationships point at things that exist? | `FOREIGN KEY` (only with `PRAGMA foreign_keys = ON`) | `FOREIGN KEY constraint failed` |
| **Semantic (domain)** | Does the value make sense? | `CHECK`, `STRICT` types, generated columns, triggers | `CHECK constraint failed: value BETWEEN -273.15 AND 5000` |

## Task A: the acceptance test

Script: [acceptance-test.sql](acceptance-test.sql) · Output: [acceptance-test-results.txt](acceptance-test-results.txt)

### What the unconstrained table accepted

`CREATE TABLE t(sensor_id INTEGER, metric TEXT, value REAL)` accepted all three workbook rows and every row I added to try to break it:

| Row I inserted | What got stored |
|---|---|
| `(1,'temp_c',9000)` | 9,000 °C, impossible for a machine |
| `(1,'temp_c','hot')` | the **text** `hot` in a `REAL` column (`typeof` = `text`) |
| `(2,'bogus',-500)` | an invented metric and a value below absolute zero |
| `(NULL, NULL, NULL)` | a completely empty row |
| `('abc', 42, 'x')` | text as the sensor id, a number as the metric |
| `(1,'temp_c',9000)` again | an exact duplicate |
| `(3.7,'temp_c',-1000)` | a fractional sensor id |
| `(4,'TEMP_C','25')` | wrong upper case; `'25'` silently converted to `25.0` |

**Most surprising for me:** the text `'hot'` was stored in a column declared `REAL`. Without `STRICT`, SQLite treats the declared type only as a suggestion.

### The same table with the constraints I would ship

```sql
CREATE TABLE t2(
    sensor_id INTEGER NOT NULL,
    metric    TEXT    NOT NULL CHECK (metric IN ('temp_c','vib_rms','spindle_load')),
    value     REAL    NOT NULL CHECK (value BETWEEN -273.15 AND 5000),
    PRIMARY KEY (sensor_id, metric)
) STRICT;
```

Each INSERT run one at a time:

| Row | Rejected by | Layer | Exact error |
|---|---|---|---|
| `(1,'temp_c',41.5)` | accepted (valid) | | |
| `(2,'temp_c',9000)` | `CHECK` range | semantic | `CHECK constraint failed: value BETWEEN -273.15 AND 5000` |
| `(3,'temp_c','hot')` | `STRICT` | semantic (type) | `cannot store TEXT value in REAL column t2.value` |
| `(4,'bogus',-500)` | `CHECK` list | semantic | `CHECK constraint failed: metric IN ('temp_c','vib_rms','spindle_load')` |
| `(NULL, NULL, NULL)` | `NOT NULL` | entity | `NOT NULL constraint failed: t2.sensor_id` |
| `('abc','temp_c',20)` | `STRICT` | semantic (type) | `cannot store TEXT value in INTEGER column t2.sensor_id` |
| `(1,'temp_c',41.5)` again | `PRIMARY KEY` | entity | `UNIQUE constraint failed: t2.sensor_id, t2.metric` |
| `(5,'temp_c',-1000)` | `CHECK` range | semantic | `CHECK constraint failed: value BETWEEN -273.15 AND 5000` |
| `(6,'TEMP_C',25)` | `CHECK` list (case-sensitive) | semantic | `CHECK constraint failed: metric IN ('temp_c','vib_rms','spindle_load')` |
| `(7,'temp_c','25')` | **accepted** | | `STRICT` converts text that is a clean number (stored as `25.0`, type `real`) |
| `(8,'vib_rms',30)` | **accepted** | | an integer is allowed in a `REAL` column |
| `(9,'temp_c',3.7e3)` | **accepted** | | 3,700 °C is inside the allowed range |

### Follow-ups

- **`CHECK` with `NULL`:** a `CHECK` lets `NULL` through. For `CHECK`, a missing value is "unknown", and only a definite "false" is rejected. That is why `NOT NULL` has to be added separately ([output](acceptance-test-results.txt), `null_rows_accepted = 1`).
- **Plausible but wrong values:** 3,700 °C passes because it is inside -273.15 to 5000. The range stops what is **physically impossible**, not what is **wrong for this machine**. A tighter range per metric, or a trigger that compares with the machine's normal values, would be needed.
- **`STRICT` is not as strict as it sounds:** the text `'25'` was accepted into a `REAL` column, because it converts to a number without losing anything. Only text that is not a number, like `'hot'`, is refused.

## Task B: share with another pod

_Pending._ My pod has not yet documented a pod-to-pod exchange for this module. This section will be filled in after we discuss it.
