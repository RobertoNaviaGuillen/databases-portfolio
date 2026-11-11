-- Round 4b: plans, a correctness check, and the race (warm-up, then A and B alternated 3 times).
-- Each timed query is wrapped in SELECT COUNT(*) FROM (...): the full join/scan and GROUP BY still run,
-- but only one line (350 groups) is printed, so the Run Time lines stay readable.
--   sqlite3 module-05/normalize.db ".read module-05/race.sql"
.headers on
.mode column

.print '== Plan A (normalized, four-way join)'
EXPLAIN QUERY PLAN
SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) AS cost
FROM job j
JOIN machine m   ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p      ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;

.print '== Plan B (denormalized, one table)'
EXPLAIN QUERY PLAN
SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;

.print '== Same answer? (groups and total cost of A and B)'
SELECT 'A' AS q, COUNT(*) AS groups, SUM(cost) AS total FROM (
  SELECT m.machine_id, j.technician, SUM(p.part_price) AS cost
  FROM job j JOIN machine m ON m.machine_id = j.machine_id
  JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no
  WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician)
UNION ALL
SELECT 'B', COUNT(*), SUM(cost) FROM (
  SELECT machine_id, technician, SUM(part_price) AS cost FROM report_jobpart
  WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);

.mode list
.headers off
-- warm-up: one untimed run of each, to load the pages into the cache
SELECT COUNT(*) AS A_groups FROM (SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) FROM job j JOIN machine m ON m.machine_id = j.machine_id JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS B_groups FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
.print '== Timed runs, alternating A and B 5 times'
.timer on
SELECT COUNT(*) AS A_groups FROM (SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) FROM job j JOIN machine m ON m.machine_id = j.machine_id JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS B_groups FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) AS A_groups FROM (SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) FROM job j JOIN machine m ON m.machine_id = j.machine_id JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS B_groups FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) AS A_groups FROM (SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) FROM job j JOIN machine m ON m.machine_id = j.machine_id JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS B_groups FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) AS A_groups FROM (SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) FROM job j JOIN machine m ON m.machine_id = j.machine_id JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS B_groups FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
SELECT COUNT(*) AS A_groups FROM (SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) FROM job j JOIN machine m ON m.machine_id = j.machine_id JOIN job_part jp ON jp.job_id = j.job_id JOIN part p ON p.part_no = jp.part_no WHERE j.done_on >= date('2026-03-01') GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS B_groups FROM (SELECT machine_id, site, technician, SUM(part_price) FROM report_jobpart WHERE done_on >= date('2026-03-01') GROUP BY machine_id, technician);
.timer off
