-- Task 6, Step 3: the shop manager's questions
-- Run from the repo root:  sqlite3 module-01/telemetry.db < module-01/queries.sql
.echo on
.mode column
.headers on
.timer on

-- 1. How many readings per machine?
SELECT machine, COUNT(*) AS n FROM readings GROUP BY machine;

-- 2. What was the peak vibration per machine in these two days?
SELECT machine, MAX(vib_rms) AS peak_vib FROM readings GROUP BY machine;

-- 3. How many readings exceeded a 2.0 mm/s vibration alarm?
SELECT COUNT(*) FROM readings WHERE vib_rms > 2.0;
