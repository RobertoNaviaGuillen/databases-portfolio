-- Task 1: prove the constraints work. Run after setup.sql:
--   sqlite3 module-04/edge.db ".read module-04/task1-constraints.sql"
PRAGMA foreign_keys = ON;
.echo on
.headers on
.mode column

-- valid
INSERT INTO sensor VALUES (1,'cnc-01','temp_c','degC'), (2,'cnc-01','vib_rms','mm/s');
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:00', 41.5, 1);

-- rejected: domain check (impossible temperature)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:01', 9000, 1);
-- rejected: STRICT type (text into a REAL)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:02', 'hot', 1);
-- rejected: referential integrity (sensor 99 does not exist)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (99,'2026-03-01 08:00:03', 40, 1);
-- rejected: entity integrity (duplicate sensor for the same machine+metric)
INSERT INTO sensor VALUES (3,'cnc-01','temp_c','degC');

-- the generated column computes energy_j = value * interval_s
SELECT reading_id, sensor_id, ts, value, interval_s, energy_j FROM reading;

-- extra: the same foreign key is NOT checked when the pragma is off
PRAGMA foreign_keys = OFF;
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (99,'2026-03-01 08:00:03', 40, 1);
SELECT reading_id, sensor_id, value FROM reading WHERE sensor_id = 99;
DELETE FROM reading WHERE sensor_id = 99;           -- clean up the orphan again
PRAGMA foreign_keys = ON;
