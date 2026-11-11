# Reflection 4 (Module 4): Data Integrity, Constraints & Edge Triggers

Back to [Module 4](../module-04/README.md)

## What worked?

I liked seeing the database itself block invalid data: every bad row in the acceptance test was refused with its own error message (`CHECK`, `STRICT`, `NOT NULL`, `PRIMARY KEY`, `FOREIGN KEY`). At the same time it showed me that the constraints still need adjusting: a temperature of 3,700 °C was accepted because it is inside the allowed range, even though no machine could reach it. A range only stops what is physically impossible, not what is wrong for this machine.

## What broke? What was difficult?

Compared with Module 3, this module was easy to understand for me. Both of my predictions were right: loading the same file twice into a table without a key duplicates every row, and the alarm trigger makes the ingest slower (in my benchmark about 2.2× slower). The only thing that needed care was the benchmark itself: without a warm-up run the numbers jumped between 3% and 100% slower.

## How did my mental model shift?

Before, I thought a database stores whatever you give it. Now I know that it only does that if nobody adds rules. With `STRICT`, `CHECK`, keys and triggers, the database refuses bad data at the moment it is written, so no application can forget to check it.

## What surprised me?

That `CHECK` lets `NULL` through. A missing value counts as "unknown", not as "false", so the check does not reject it. A `CHECK` always needs a `NOT NULL` next to it.

## Help and extra work

- I used **Claude (AI)** as an assistant to build the database, write the scripts and the benchmark, and run the tasks, and it explained each result to me in simple terms.
