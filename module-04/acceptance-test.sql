-- Pod Study, Task A: the acceptance test.
-- Run:  sqlite3 :memory: ".read module-04/acceptance-test.sql"
.echo on
.headers on
.mode column

-- PART 1: an unconstrained table accepts everything
CREATE TABLE t(sensor_id INTEGER, metric TEXT, value REAL);
INSERT INTO t VALUES (1,'temp_c',9000), (1,'temp_c','hot'), (2,'bogus',-500);
-- my own attempts to break it
INSERT INTO t VALUES (NULL, NULL, NULL);            -- a completely empty row
INSERT INTO t VALUES ('abc', 42, 'x');              -- text as sensor id, number as metric
INSERT INTO t VALUES (1,'temp_c',9000);             -- exact duplicate of the first row
INSERT INTO t VALUES (3.7,'temp_c',-1000);          -- fractional id, below absolute zero
INSERT INTO t VALUES (4,'TEMP_C','25');             -- wrong case, number as text
SELECT rowid, sensor_id, typeof(sensor_id) AS id_type, metric, value, typeof(value) AS value_type FROM t;

-- PART 2: the same table with the constraints I would ship
CREATE TABLE t2(
    sensor_id INTEGER NOT NULL,
    metric    TEXT    NOT NULL CHECK (metric IN ('temp_c','vib_rms','spindle_load')),
    value     REAL    NOT NULL CHECK (value BETWEEN -273.15 AND 5000),
    PRIMARY KEY (sensor_id, metric)
) STRICT;
-- one INSERT at a time
INSERT INTO t2 VALUES (1,'temp_c',41.5);            -- valid, should pass
INSERT INTO t2 VALUES (2,'temp_c',9000);
INSERT INTO t2 VALUES (3,'temp_c','hot');
INSERT INTO t2 VALUES (4,'bogus',-500);
INSERT INTO t2 VALUES (NULL, NULL, NULL);
INSERT INTO t2 VALUES ('abc', 'temp_c', 20);
INSERT INTO t2 VALUES (1,'temp_c',41.5);
INSERT INTO t2 VALUES (5,'temp_c',-1000);
INSERT INTO t2 VALUES (6,'TEMP_C',25);
INSERT INTO t2 VALUES (7,'temp_c','25');            -- text that looks like a number
INSERT INTO t2 VALUES (8,'vib_rms',30);             -- integer into a REAL column
INSERT INTO t2 VALUES (9,'temp_c',3.7e3);           -- plausible but wrong? 3,700 degC passes the range
SELECT sensor_id, metric, value, typeof(value) AS value_type FROM t2;

-- Follow-up 1: what does CHECK do with NULL?
CREATE TABLE t3(value REAL CHECK (value BETWEEN -273.15 AND 5000)) STRICT;
INSERT INTO t3 VALUES (NULL);                       -- CHECK sees NULL as "unknown", not "false"
SELECT count(*) AS null_rows_accepted FROM t3 WHERE value IS NULL;
