# Module 6b: Project ticket

Back to [Module 6b](README.md)

**Project:** ShelfWise Medical: Inventory, Cold Chain and Order Fulfilment · **Repository:** [shelfwise-medical/shelfwise-db](https://github.com/shelfwise-medical/shelfwise-db) · **Presentation:** 17 December 2026

**Status:** presented to the professor and approved. His feedback: make it a warehouse for **medical supplies**, add the complexity of the **cold chain**, and tell it as a **story**. He also asked us to choose between a cloud server and a client-server setup (our answer is below).

**ShelfWise Medical** (a fictional company) is a regional distribution warehouse in Bielefeld for pharmacies, clinics and doctors' practices. About a third of its products are cold-chain goods (vaccines, insulin, biologics) that must stay between 2 °C and 8 °C. In our story a cold room fails over a weekend and a batch of insulin that had been too warm is still shipped on Monday, because the system listed it as available.

| | |
|---|---|
| **1. The person** | **Jonas Weber, inventory planner**, who decides what to reorder before an order can no longer be fulfilled. Also: **Dr. Lena Hoffmann, quality manager** (releases or blocks quarantined batches, handles recalls), the receiving clerk and the warehouse picker. |
| **2. The problem** | Never ship what is not safe to ship (expired, or quarantined after a temperature excursion), and see shortages **before** an order fails, not when the picker finds an empty shelf. |
| **3. The first query** | *"Which products have insufficient **safe available stock** to fulfil outstanding customer orders, and how much more is needed?"* where safe available stock = on hand − allocated to other orders − quarantined − expired. |
| **4. The data source** | No real data exists, so we generate a **reproducible dataset** from a seeded script: about **120,000 stock movements** and **15,000 order lines**, with batches, expiry dates, cold-room sensor readings, deliberate shortages and one temperature excursion. |

**Cloud or client-server?** We chose **local-first**: the operational database is **SQLite** on a machine inside the warehouse, so receiving, picking, the sensors and the quarantine trigger keep working when the internet is down. If the database were in the cloud, an outage would stop the temperature readings and the quarantine at the same time, which a cold chain cannot accept (in Module 6b a stopped server meant `connection refused` for every client). A nightly Parquet export goes to off-site storage for reports and backups (Module 6a). We will measure concurrent writes; if `database is locked` happens too often, that is our measured reason to move to PostgreSQL on-premises.

**What it demonstrates from the course:** a 3NF data model (Modules 2, 5), constraints and triggers so stock can never go negative and quarantined batches cannot be picked, `UPSERT` against duplicated movements and sensor readings (Module 4), indexes justified with query plans (Module 3), and our main measured decision: calculating stock from all movements vs. keeping it in a stock table maintained by a trigger (Modules 4 and 5).

**Team (8 members, Pod 16 merged with Pod 06) and my role:** I am responsible for the **data generator**. Roles, sprint plan and each member's instructions are in the [project repository](https://github.com/shelfwise-medical/shelfwise-db).
