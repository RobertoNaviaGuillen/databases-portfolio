-- Module 2, Task 1: determine the cardinalities with counts, not guesses
-- Run from the repo root:  sqlite3 module-02/legacy.db ".read module-02/cardinality.sql"
.echo on
.mode column
.headers on
.timer on

-- Machine 1:n MaintenanceJob: fewer distinct machines than jobs, so one machine has several jobs
SELECT COUNT(*) AS jobs, COUNT(DISTINCT machine_name) AS machines_used FROM maint_job;
SELECT machine_name, COUNT(*) AS jobs FROM maint_job GROUP BY machine_name ORDER BY jobs DESC;

-- Technician 1:n MaintenanceJob: a technician performs many jobs (Beier: 2)
SELECT technician, COUNT(*) AS jobs FROM maint_job GROUP BY technician ORDER BY jobs DESC;

-- MaintenanceJob m:n Part, side 1: how many parts does each job use? (the m:n hiding in a text column)
SELECT job_id, parts_used,
       LENGTH(parts_used) - LENGTH(REPLACE(parts_used, ',', '')) + 1 AS n_parts
FROM maint_job;

-- MaintenanceJob m:n Part, side 2: in how many jobs does each part appear?
SELECT p.part_no, COUNT(DISTINCT j.job_id) AS used_in_jobs
FROM (SELECT DISTINCT part_no FROM part) p
LEFT JOIN maint_job j ON ',' || j.parts_used || ',' LIKE '%,' || p.part_no || ',%'
GROUP BY p.part_no;

-- Machine 1:1 nameplate (serial_no): every machine has exactly one serial number and no serial repeats
SELECT COUNT(*) AS machines, COUNT(DISTINCT serial_no) AS distinct_serials,
       COUNT(DISTINCT machine_name) AS distinct_names FROM machine;
