-- Round 3b: decompose flat_jobpart into 3NF (from the workbook), with foreign keys switched ON.
--   sqlite3 module-05/normalize.db ".read module-05/normalize.sql"
PRAGMA foreign_keys = ON;
.headers on
.mode column

DROP TABLE IF EXISTS job_part;
DROP TABLE IF EXISTS job;
DROP TABLE IF EXISTS part;
DROP TABLE IF EXISTS machine;

CREATE TABLE machine(machine_id TEXT PRIMARY KEY, site TEXT NOT NULL);
CREATE TABLE part(part_no TEXT PRIMARY KEY, part_price REAL NOT NULL);
CREATE TABLE job(job_id INTEGER PRIMARY KEY, machine_id TEXT NOT NULL
                 REFERENCES machine(machine_id), technician TEXT NOT NULL, done_on TEXT NOT NULL);
CREATE TABLE job_part(job_id INTEGER REFERENCES job(job_id),
                      part_no TEXT REFERENCES part(part_no),
                      PRIMARY KEY (job_id, part_no));

INSERT INTO machine SELECT DISTINCT machine_id, site FROM flat_jobpart;
INSERT INTO part    SELECT DISTINCT part_no, CAST(part_price AS REAL) FROM flat_jobpart;
INSERT INTO job     SELECT DISTINCT job_id, machine_id, technician, done_on FROM flat_jobpart;
INSERT INTO job_part SELECT DISTINCT job_id, part_no FROM flat_jobpart;

-- integrity check: the join must reproduce the row count of the flat table
SELECT (SELECT COUNT(*) FROM flat_jobpart)  AS flat_rows,
       (SELECT COUNT(*) FROM job_part)      AS normalized_rows;

-- rows per table, and the foreign-key check (no output = no orphans)
SELECT (SELECT COUNT(*) FROM machine) AS machines, (SELECT COUNT(*) FROM part) AS parts,
       (SELECT COUNT(*) FROM job) AS jobs, (SELECT COUNT(*) FROM job_part) AS job_parts;
PRAGMA foreign_key_check;

-- why only 10 parts? k runs 1..10, so (k % 40) + 1 only ever reaches 2..11
SELECT MIN(part_no) AS first_part, MAX(part_no) AS last_part, COUNT(DISTINCT part_no) AS distinct_parts FROM flat_jobpart;
