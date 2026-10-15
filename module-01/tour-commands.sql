-- Task 4: sqlite3 shell tour
-- Run from the repo root:  sqlite3 module-01/tour.db < module-01/tour-commands.sql

-- SQL: create a table and add rows (SQL ends with ; — dot-commands do not)
DROP TABLE IF EXISTS reading;
CREATE TABLE reading(machine TEXT, vib REAL);
INSERT INTO reading VALUES ('cnc-01', 1.2), ('cnc-02', 2.4), ('cnc-01', 0.9);

-- capture the session (commands + results) into a file
.output module-01/shell-tour.txt
.echo on

-- what tables exist now?
.tables

-- the CREATE statement that made it
.schema reading

-- readable, aligned columns with a header
.mode column
.headers on
SELECT machine, max(vib) AS peak FROM reading GROUP BY machine;

-- the same query, now timed (CPU time)
.timer on
SELECT machine, max(vib) AS peak FROM reading GROUP BY machine;
.timer off
.echo off

-- the whole schema + data as SQL
.output module-01/tour.sql
.dump

-- back to the screen
.output stdout
