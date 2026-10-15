# Reflection 1 — Module 1: Introduction & Local-First Foundations

Back to [Module 1](../module-01/README.md)

## What worked? What was good?

SQL Island was the best part of the session. The game takes you by the hand: each step introduces one new idea (a table, a column, a filter, an update), so I learned the basics of SQL without reading any theory first.

## What broke? What was difficult?

The hardest part was the **order and the exact way of writing** a query to get the result I wanted:

- when to use `*` and when to name the columns,
- where the `=` goes (`WHERE column = 'value'`),
- that text needs single quotes (`'friendly'`) but numbers don't,
- that every query has to start with a command like `SELECT`.

Small detail, big impact: on my keyboard the accent key gave me `¨` instead of the straight quote `'`, and the query failed until I found the right key.

## How did my mental model shift?

Not much. I already had an idea of what a database is, and it is close to what I did today: tables with rows and columns that you ask questions to. What is new for me is that a database can be **just a file** (SQLite) inside the program, without any server.

## How did I verify AI suggestions?

Task 7 was the part I understood least, so this is what I want to take away from it:

- An AI-generated query can **run without errors and still answer a different question**. The AI read "overnight (after 18:00)" as 18:00–midnight; if "overnight" means 18:00–06:00, the ranking of the machines flips.
- To check it: run it on the real data, check that the number of rows makes sense (43,200 = 6 h × 1,200 readings/h × 2 days × 3 machines), look at the plan with `EXPLAIN QUERY PLAN`, and compare it with other possible versions.

I still need more practice to do this on my own — I want to ask about it in the next session.

## Help and extra work

- I used **Claude (AI)** as an assistant to set up the repository, install the toolchain (`uv`, `sqlite3`) and run the scripts for Tasks 3, 4, 6 and 7, and it explained each step to me. I played SQL Island myself.
- Task Pod: [Leviscus Njeru](https://github.com/leviscusgnjeru/databases), [Ian Okach](https://github.com/Okach81/Databases_ianportfolio).
