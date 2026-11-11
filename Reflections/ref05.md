# Reflection 5 (Module 5): Normalization vs. Denormalization

Back to [Module 5](../module-05/README.md)

## What worked?

I liked exploring both options for the dashboard and then having to choose: the copied (denormalized) table, which without its index was about 19% faster to read but uses 2.7× the storage and needs 4,000 rows changed for one site update, or the normalized one, which is a little slower but stores every fact once, so there is no risk of old data. I chose the normalized design, because a difference of a few milliseconds does not matter for a dashboard that refreshes every 30 seconds ([memo](../module-05/memo.md)).

## What broke? What was difficult?

The functional dependencies in Round 1. In the five rows, `cnc-01` always appeared with `tech-0`, so I thought the machine determines the technician. The 200k table proved it was a coincidence: `cnc-02` was serviced by all 7 technicians. Five rows cannot prove a rule, and one counter-example is enough to break it.

## How did my mental model shift?

I realized that copying everything into one table is not always faster. With its index, the copied table was slower than the four-way join (121 ms vs. 92 ms), and even without the index it only won by about 16 ms, because the joins here were cheap. Denormalization only pays when the join is the expensive part.

## Feedback on the format

The module asked for feedback on the new round-based format. I prefer the previous format with a separate pod study phase.

## Help and extra work

- I used **Claude (AI)** as an assistant to build the database, write the scripts and run the benchmarks, and it explained each result to me in simple terms.
- The FD list in Round 1 was compared with Claude's answer; it was right about `machine_id → technician` being only observed.
