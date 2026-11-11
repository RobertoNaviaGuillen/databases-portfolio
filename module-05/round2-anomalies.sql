-- Round 2: break the five-row table on purpose.
-- Run:  sqlite3 :memory: ".read module-05/round2-anomalies.sql"
.echo on
.headers on
.mode column

CREATE TABLE flat5(
  job_id INTEGER, machine_id TEXT, site TEXT,
  technician TEXT, part_no TEXT, part_price REAL
);
INSERT INTO flat5 VALUES
  (1,'cnc-01','Gütersloh','tech-0','P-0001',6.00),
  (1,'cnc-01','Gütersloh','tech-0','P-0002',7.00),
  (2,'cnc-02','Gütersloh','tech-1','P-0001',6.00),
  (2,'cnc-02','Gütersloh','tech-1','P-0003',8.50),
  (3,'cnc-01','Gütersloh','tech-0','P-0003',8.50);

-- 1. UPDATE ANOMALY: move cnc-01 to Bielefeld.
-- Correct version: one fact, but 3 rows must change.
UPDATE flat5 SET site = 'Bielefeld' WHERE machine_id = 'cnc-01';
SELECT changes() AS rows_touched;
-- What a second session might do: fix only "its" job. The fact now disagrees with itself.
UPDATE flat5 SET site = 'Gütersloh' WHERE machine_id = 'cnc-01' AND job_id = 3;
SELECT DISTINCT machine_id, site FROM flat5 WHERE machine_id = 'cnc-01';

-- 2. INSERT ANOMALY: a new part P-0004 (9.75) that no job has used yet.
-- There is no place for it without inventing a job: the only way is a row full of NULLs.
INSERT INTO flat5(part_no, part_price) VALUES ('P-0004', 9.75);
SELECT * FROM flat5 WHERE part_no = 'P-0004';
DELETE FROM flat5 WHERE job_id IS NULL;            -- undo the fake row

-- 3. DELETE ANOMALY: P-0002 is used only by job 1. Delete that job-part row...
DELETE FROM flat5 WHERE job_id = 1 AND part_no = 'P-0002';
-- ...and the price of P-0002 (7.00) is gone from the database:
SELECT COUNT(*) AS rows_that_know_price_of_P0002 FROM flat5 WHERE part_no = 'P-0002';
