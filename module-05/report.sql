-- Round 4a: the denormalized reporting table (from the workbook).
--   sqlite3 module-05/normalize.db ".read module-05/report.sql"
DROP TABLE IF EXISTS report_jobpart;
CREATE TABLE report_jobpart AS
SELECT j.job_id, m.machine_id, m.site, j.technician, jp.part_no,
       p.part_price, j.done_on
FROM job j
JOIN machine m  ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p     ON p.part_no = jp.part_no;
CREATE INDEX ix_report_machine ON report_jobpart(machine_id);
