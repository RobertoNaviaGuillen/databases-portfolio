-- Task 2: idempotent edge ingestion with UPSERT. Run after task1-constraints.sql:
--   sqlite3 module-04/edge.db ".read module-04/task2-upsert.sql"
PRAGMA foreign_keys = ON;
.echo on
.headers on
.mode column

-- Make (sensor_id, ts) a genuine natural key so replays collide:
CREATE UNIQUE INDEX ux_reading_sensor_ts ON reading(sensor_id, ts);

-- a plain INSERT of the same reading is now refused
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:00', 41.7, 1);

-- Replay-safe ingest: insert, or update if the exact reading already exists.
INSERT INTO reading(sensor_id, ts, value, interval_s)
VALUES (1,'2026-03-01 08:00:00', 41.7, 1)          -- same key, corrected value (sensor retried)
ON CONFLICT(sensor_id, ts) DO UPDATE SET value = excluded.value;

-- Show that there is still exactly one row for that key:
SELECT sensor_id, ts, value FROM reading WHERE sensor_id = 1;
