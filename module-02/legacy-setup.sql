-- Module 2: the deliberately flawed legacy maintenance schema (from the workbook)
-- Run from the repo root:  sqlite3 module-02/legacy.db ".read module-02/legacy-setup.sql"
DROP TABLE IF EXISTS machine;
DROP TABLE IF EXISTS part;
DROP TABLE IF EXISTS maint_job;

CREATE TABLE machine (
    machine_name TEXT,          -- no PK, no NOT NULL
    serial_no    TEXT,
    site         TEXT,
    installed    TEXT           -- a date stored as free text
);

CREATE TABLE part (
    part_no      TEXT,          -- natural key, but not declared UNIQUE
    description  TEXT,
    unit_price   TEXT           -- a number stored as text!
);

CREATE TABLE maint_job (
    job_id       INTEGER,
    machine_name TEXT,          -- a *name*, not a foreign key
    technician   TEXT,
    done_on      TEXT,
    parts_used   TEXT           -- e.g. 'P-1001,P-1002'  <-- violates 1NF
);

INSERT INTO machine VALUES
  ('cnc-01','SN-88120','Gütersloh','2019-03-11'),
  ('cnc-02','SN-88121','Gütersloh','2019-03-11'),
  ('cnc-03','SN-88122','Bielefeld','2021-07-02'),
  ('RANDOM-NAME','SN-90000','Gütersloh','unknown');

INSERT INTO part VALUES
  ('P-1001','Ball bearing 6203','12.50'),
  ('P-1002','Spindle belt','48.00'),
  ('P-1003','Coolant filter','9.90'),
  ('P-1003','Coolant filter','9.90');   -- duplicate row!

INSERT INTO maint_job VALUES
  (1,'cnc-01','Beier','2026-01-08','P-1001,P-1002'),
  (2,'cnc-02','Klaas','2026-02-14','P-1003'),
  (3,'cnc-05','Beier','2026-02-20','P-1001'),  -- machine cnc-05 does not exist!
  (4,'cnc-01','Werther','2026-03-01',NULL);
