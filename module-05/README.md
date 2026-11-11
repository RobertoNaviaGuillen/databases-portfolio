# Module 5: Normalization vs. Denormalization Benchmarking Studio

Course: Databases (HSBI) · Session 5 · [Module page](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/05-normalization-vs-denormalization.md) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md) · [Back to portfolio](../README.md)

## Learning Goals

By the end of this module, I can:

1. Derive **functional dependencies** from a relation and identify candidate keys.
2. Normalize a relation to **1NF, 2NF, and 3NF**, explaining the anomaly each step removes.
3. **Denormalize deliberately** to speed up a hot read path, and predict what it costs on writes and storage.
4. **Measure** the trade-off: query latency, write cost, and database size, before and after.
5. Decide, and *defend*, where a schema should sit on the normalization spectrum for a given workload.

## Rounds

All notes, numbers and explanations are in [normalization-notes.md](normalization-notes.md).

- [x] 1 · See it: FD list, two ER sketches, LLM diff ([notes](normalization-notes.md#round-1-see-it-dependencies-and-two-pictures), [FD check](round1-fd-check.sql), [output](round1-results.txt))
- [x] 2 · Break it: update, insert and delete anomaly ([script](round2-anomalies.sql), [output](round2-results.txt), [notes](normalization-notes.md#round-2-break-it-the-three-anomalies))
- [x] 3 · Build it: 200k flat table and 3NF ([setup.sql](setup.sql), [normalize.sql](normalize.sql), [output](normalize-results.txt), [notes](normalization-notes.md#round-3-build-it-200k-rows-and-3nf))
- [x] 4 · Race it: report table, two plans, timings ([report.sql](report.sql), [race.sql](race.sql), [output](race-results.txt), [notes](normalization-notes.md#round-4-race-it-normalized-vs-denormalized))
- [x] 5 · Price it: rows touched, storage, index experiment ([price.sql](price.sql), [output](price-results.txt), [race without index](race-noindex-results.txt), [notes](normalization-notes.md#round-5-price-it-writes-and-storage))
- [x] 6 · Decide: [memo.md](memo.md)
- [x] 7 · Harvest: [notes](normalization-notes.md#round-7-harvest)
- [ ] Stretcher (DuckDB): not done
- [x] Reflection: [ref05.md](../Reflections/ref05.md)

### Rebuild everything

Run from the repo root (Git Bash). `normalize.db` is not committed.

```sh
rm -f module-05/normalize.db
sqlite3 module-05/normalize.db ".read module-05/setup.sql"
sqlite3 module-05/normalize.db ".read module-05/round1-fd-check.sql"
sqlite3 :memory: ".read module-05/round2-anomalies.sql"
sqlite3 module-05/normalize.db ".read module-05/normalize.sql"
sqlite3 module-05/normalize.db ".read module-05/report.sql"
sqlite3 module-05/normalize.db ".read module-05/race.sql"
sqlite3 module-05/normalize.db ".read module-05/price.sql"
sqlite3 module-05/normalize.db ".read module-05/race.sql"
sqlite3 module-05/normalize.db ".read module-05/harvest-price-text.sql"
```

(`price.sql` drops `ix_report_machine`, so the second `race.sql` is the race without the index.)

## Results at a glance

| Design | Dashboard query (ms, warm, median) | Rows changed by one site update | Storage (KB, tables only) | Redundancy? |
|---|---|---|---|---|
| Normalized (3NF) | 92.0 (Round 4) / 85.3 (Round 5 rerun) | **1** | 3,976 | none |
| Denormalized (report) | 121.2 with index / **69.1 without index** | **4,000** | 10,832 | site/technician/price repeated |

- **My predictions:** B faster by a little (wrong with the index, right without it); 4,000 rows for one site change (right).
- **Main finding:** the copied table only wins once its index is dropped, and then only by about 19%, because on this dataset the joins are cheap (50 machines, 10 parts, all in memory).
- **Decision** ([memo](memo.md)): keep the dashboard on 3NF; if the production join becomes expensive, add the copy on purpose and keep it fresh with triggers.
