-- Round 5: price it (writes and storage), then the index experiment.
-- Run after report.sql:  sqlite3 module-05/normalize.db ".read module-05/price.sql"
.headers on
.mode column

.print '== Change the site of one machine: 3NF table vs. report table'
.timer on
UPDATE machine        SET site = 'Bielefeld' WHERE machine_id = 'cnc-02';
SELECT changes() AS rows_touched_3nf;
UPDATE report_jobpart SET site = 'Bielefeld' WHERE machine_id = 'cnc-02';
SELECT changes() AS rows_touched_report;
.timer off

.print '== Storage (dbstat: bytes of all pages per design, indexes included)'
SELECT 'normalized (job + job_part + part + machine)' AS design,
       (SELECT SUM(pgsize) FROM dbstat WHERE name IN ('job','job_part','part','machine')) AS bytes;
SELECT 'denormalized (report_jobpart)' AS design,
       (SELECT SUM(pgsize) FROM dbstat WHERE name = 'report_jobpart') AS bytes;
-- the same, split per object (tables and their indexes)
SELECT name, SUM(pgsize) AS bytes FROM dbstat
WHERE name IN ('job','job_part','part','machine','report_jobpart','ix_report_machine',
               'sqlite_autoindex_job_part_1','sqlite_autoindex_machine_1','sqlite_autoindex_part_1')
GROUP BY name ORDER BY bytes DESC;

.print '== Index experiment: B with the index, then without it'
.mode list
.headers off
EXPLAIN QUERY PLAN SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician;
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
.timer on
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
.timer off
DROP INDEX ix_report_machine;
EXPLAIN QUERY PLAN SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician;
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
.timer on
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
.timer off
