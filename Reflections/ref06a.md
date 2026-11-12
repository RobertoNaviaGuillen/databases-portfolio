# Reflection 6a (Module 6a): The Analytical Engine (DuckDB)

Back to [Module 6a](../module-06a/README.md)

## What worked?

I liked learning a new piece of software for working with databases. Until Module 5 I had only used one database engine, SQLite; DuckDB is the first different engine I actually used. The most important thing I learned is that neither engine is better: each one is built for a different job. SQLite is the right tool for the work that happens all day, one row at a time, and DuckDB for big reports over millions of rows.

## What broke? What was difficult?

At first I was confused by Parquet, because I thought it was another piece of software. Then I understood that it is only a file format, like `.xlsx` or `.pdf`: it stores the data by columns and compressed, and DuckDB is the program that reads it.

## How did my mental model shift?

I learned that not everything can be done with a single piece of software. In my memo I used both: the month-end report moves to a Parquet file read by DuckDB, and everything used constantly during the day stays in SQLite ([memo](../module-06a/memo.md)).

## What surprised me?

The size of the time difference. I expected DuckDB to be faster, and predicted 10 to 20 times, but it was about **75 times faster** for the dashboard aggregate (2,480 ms vs. 33 ms) and **107 times** for the monthly report. The other direction surprised me just as much: for 1,000 single-row inserts, DuckDB took about 5 seconds and SQLite about 1 millisecond.

## Help and extra work

- I used **Claude (AI)** as an assistant to write and run the scripts and benchmarks, and it explained each result to me in simple terms.
- While checking the race results, we found that the workbook's monthly query uses `strftime` with the argument order of DuckDB in both engines, so SQLite returned empty months; the corrected race checks that both engines give identical results before timing ([details](../module-06a/duckdb-notes.md#the-workbooks-monthly-query-compared-two-different-answers)).
