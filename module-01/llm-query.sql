-- Task 7: LLM-assisted SQL profiling
-- Run from the repo root:  sqlite3 module-01/telemetry.db < module-01/llm-query.sql
.echo on
.mode column
.headers on

-- A. The LLM's query (as generated)
.timer on
SELECT machine, AVG(spindle_load) AS avg_load
FROM readings
WHERE time(ts) >= '18:00:00'
GROUP BY machine
ORDER BY avg_load DESC;
.timer off

-- Profile it
EXPLAIN QUERY PLAN
SELECT machine, AVG(spindle_load) AS avg_load
FROM readings
WHERE time(ts) >= '18:00:00'
GROUP BY machine
ORDER BY avg_load DESC;

-- B. Break it #1: a plain string comparison against a full timestamp.
--    Looks similar, but means "everything after Monday 18:00" (incl. Tuesday daytime).
SELECT machine, AVG(spindle_load) AS avg_load
FROM readings
WHERE ts > '2026-01-05 18:00:00'
GROUP BY machine
ORDER BY avg_load DESC;

-- C. Break it #2: the sloppy LIKE version. Matches '18' anywhere in the text
--    (minutes, seconds, dates), not "after 18:00".
SELECT COUNT(*) AS like_rows FROM readings WHERE ts LIKE '%18%';
SELECT COUNT(*) AS evening_rows FROM readings WHERE time(ts) >= '18:00:00';

-- D. Ambiguity: does "overnight" include 00:00-06:00? The LLM assumed 18:00-24:00 only.
SELECT machine, AVG(spindle_load) AS avg_load
FROM readings
WHERE time(ts) >= '18:00:00' OR time(ts) < '06:00:00'
GROUP BY machine
ORDER BY avg_load DESC;
