-- Round 1: test the candidate FDs on the 200k flat table.
-- An FD X -> Y holds in the data if no X value has more than one Y value.
--   sqlite3 module-05/normalize.db ".read module-05/round1-fd-check.sql"
.headers on
.mode column

SELECT 'machine_id -> site'       AS fd, COUNT(*) AS violating_values FROM (SELECT machine_id FROM flat_jobpart GROUP BY machine_id HAVING COUNT(DISTINCT site) > 1)
UNION ALL
SELECT 'part_no -> part_price',          COUNT(*) FROM (SELECT part_no    FROM flat_jobpart GROUP BY part_no    HAVING COUNT(DISTINCT part_price) > 1)
UNION ALL
SELECT 'job_id -> technician',           COUNT(*) FROM (SELECT job_id     FROM flat_jobpart GROUP BY job_id     HAVING COUNT(DISTINCT technician) > 1)
UNION ALL
SELECT 'job_id -> machine_id',           COUNT(*) FROM (SELECT job_id     FROM flat_jobpart GROUP BY job_id     HAVING COUNT(DISTINCT machine_id) > 1)
UNION ALL
SELECT 'machine_id -> technician',       COUNT(*) FROM (SELECT machine_id FROM flat_jobpart GROUP BY machine_id HAVING COUNT(DISTINCT technician) > 1);

-- the counter-example for machine_id -> technician
SELECT machine_id, COUNT(DISTINCT technician) AS technicians, GROUP_CONCAT(DISTINCT technician) AS who
FROM flat_jobpart WHERE machine_id = 'cnc-02' GROUP BY machine_id;
