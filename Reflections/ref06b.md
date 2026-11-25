# Reflection 6b (Module 6b): Polyglot Persistence & the Decision

Back to [Module 6b](../module-06b/README.md)

## What worked?

I really liked logging in to the shared PostgreSQL server, because it is the closest example in this course to how a database is used in real life: one database on another machine, shared by the whole pod. When I connected, my pod mates had already added six machines, and I could read and change the same data from two different browsers ([Task 1](../module-06b/README.md#task-1-the-boundary-shared-postgresql-server)).

## What broke? What was difficult?

Understanding the difference between **authentication** and **authorization**. Authentication is the server checking *who* I am (`SELECT current_user` returned `pod16`, so the login worked). Authorization is the server deciding *what* I may do with each table. In class my pod mate Leviscus could log in but got `permission denied for table machine` until the professor granted the rights; when I connected later, the table belonged to `pod16` and all three privileges were `true`. Logging in does not mean being allowed to read.

## How did my mental model shift?

My ideas did not change much in this module. It mostly confirmed what I learned in Module 6a: there is no best engine, only the right engine for each workload. My decision record uses SQLite for four of the five workloads and DuckDB + Parquet for the month-end report ([decision record](../module-06b/decision-record.md)).

## What surprised me?

That the server could handle two writers on the same row at the same time without losing either change. While my first browser held the row for 20 seconds, the second one waited 12.2 seconds and then ran; machine 7 ended at 2, so both updates were kept. In SQLite, the second writer got `database is locked` instead.

## Help and extra work

- I used **Claude (AI)** as an assistant to write and run the JSON, key-value and two-writer scripts, to guide me step by step through the pgweb session, and to explain each result in simple terms. I ran the PostgreSQL queries myself in pgweb.
- The server outage and the defence with Pod 2 are taken from my pod mate Leviscus's records, as stated in the module.
