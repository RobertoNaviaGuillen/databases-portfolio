# Module 5: Recommendation memo to the operations lead

Back to [Module 5](README.md) · Numbers from [normalization-notes.md](normalization-notes.md#filled-in-benchmark-table)

**To:** Yasmin Kaya, operations lead
**From:** Roberto Navia Guillen
**Subject:** Should the machine-health dashboard read a copied (denormalized) table?

My recommendation is to keep serving the dashboard from the **normalized (3NF) tables** for now. On our 200,000-row test data the four-way join took a median of **85 to 92 ms**, while the copied table took **69 ms** at its best (and **121 ms** with the index it was built with), so the copy saves only about 16 to 23 ms, a difference nobody will notice on a dashboard that refreshes every 30 seconds. That small gain is paid for every day: one site change touches **1 row** in 3NF but **4,000 rows** in the copy (6.5 ms vs. 57.6 ms), and the copy uses **2.7× the storage** (10,832 KB vs. 3,976 KB). Most importantly, in 3NF every fact is stored once, so the dashboard can never show an old site, technician or price. The transactional tables (`machine`, `part`, `job`, `job_part`) must stay in 3NF in any case, because they are where the data is written and corrected.

If the production data makes the join really expensive (the 40-second case), I would add the copied table **on purpose, only for the dashboard**, and keep it fresh with **triggers**, as in Module 4: an `AFTER UPDATE` trigger on `machine`, `job` and `part` that updates the matching rows in the copy, and an `AFTER INSERT` trigger on `job_part` that adds the new row. The copy then changes in the same transaction as the original data, so it is never stale. The price is slower writes: in Module 4 a single trigger made a 10,000-row ingest about 2.2× slower, so before switching I would measure both the dashboard query and the write cost again on the production data, and build the copy **without** the `machine_id` index, which made it slower in our test.
