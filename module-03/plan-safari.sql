-- Module 3, Task A: plan safari on Module 2's legacy.db
-- Run from the repo root:  sqlite3 module-02/legacy.db ".read module-03/plan-safari.sql"
-- My predictions before running: A = SCAN, B = SEARCH, C = SCAN
.echo on
DROP INDEX IF EXISTS ix_job_tech;

-- Round 1: no index at all (the legacy tables have no primary key and no index)
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE technician = 'Beier';
EXPLAIN QUERY PLAN SELECT * FROM machine WHERE machine_name = 'cnc-02';
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE technician LIKE '%ei%';

-- Round 2: add one index on technician and re-run all three
CREATE INDEX ix_job_tech ON maint_job(technician);
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE technician = 'Beier';
EXPLAIN QUERY PLAN SELECT * FROM machine WHERE machine_name = 'cnc-02';
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE technician LIKE '%ei%';

-- Round 3: break it on purpose, WHERE clauses that defeat the index anyway
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE lower(technician) = 'beier';   -- function around the column
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE technician LIKE 'Bei%';        -- no leading wildcard: still not used (LIKE is case-insensitive)
EXPLAIN QUERY PLAN SELECT * FROM maint_job WHERE technician >= 'Bei' AND technician < 'Bej';  -- the same prefix as a range: index used

-- leave legacy.db as Module 2 built it
DROP INDEX ix_job_tech;
