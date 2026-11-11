-- Task 3: exercise the triggers. Run after triggers.sql:
--   sqlite3 module-04/edge.db ".read module-04/task3-triggers.sql"
PRAGMA foreign_keys = ON;
.echo on
.headers on
.mode column

INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (2,'2026-03-01 09:00:00', 2.7, 1);  -- alarm!
-- The workbook updates WHERE sensor_id = 2. In my edge.db sensor 2 already holds the 500 readings
-- loaded by ingest.py, so I limit the UPDATE to the one new row (otherwise 501 values would be overwritten).
UPDATE reading SET value = 1.4 WHERE sensor_id = 2 AND ts = '2026-03-01 09:00:00';             -- audit!
SELECT * FROM alarm;
SELECT * FROM audit;

-- a temperature above 2.0 must NOT raise an alarm (the trigger also checks the metric)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 09:00:00', 55.0, 1);
SELECT COUNT(*) AS alarms FROM alarm;

-- an UPSERT that changes a value also fires the audit trigger
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 09:00:00', 56.0, 1)
ON CONFLICT(sensor_id, ts) DO UPDATE SET value = excluded.value;
SELECT * FROM audit;
