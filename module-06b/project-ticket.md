# Module 6b: Project ticket

Back to [Module 6b](README.md)

**Candidate:** Warehouse Inventory and Order Fulfilment System · idea agreed with my team on 26 November 2026, for the Module 7 kickoff.

A fictional regional distribution warehouse wants to see stock movements, fulfil customer orders, and spot shortages before they disrupt operations.

| | |
|---|---|
| **1. The person** | The **inventory planner**, who monitors stock levels and makes replenishment decisions. Two more actors feed the data: the **receiving clerk**, who records incoming deliveries, and the **warehouse picker**, who processes customer orders. |
| **2. The problem** | Which products to reorder, and how much, **before** an order cannot be fulfilled. Orders move through `created → allocated → picked → packed → shipped`; a shortage found only at picking time stops the line. |
| **3. The first query** | *"Which products have insufficient available stock to fulfil outstanding customer orders, and how much additional stock is required?"* |
| **4. The data source** | No real data exists, so we generate a **reproducible dataset** from a script with a fixed seed: about **120,000 inventory movements** and **15,000 order lines**, plus product, supplier and warehouse-location records. |

**Engine:** SQLite as the primary database, with Datasette as a simple interface to show the results.

**What it lets us demonstrate:** relational modelling, transactions, constraints, triggers, `UPSERT`, joins, indexing and performance analysis. The interesting challenge is keeping inventory accurate: **no negative stock** (a `CHECK` or a trigger, as in Module 4) and **no duplicated movements** (a natural key + `UPSERT`, as in the Module 4 replay test).
