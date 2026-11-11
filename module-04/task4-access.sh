#!/bin/sh
# Task 4: access control without a server. Run from the repo root in Git Bash:
#   sh module-04/task4-access.sh > module-04/task4-results.txt 2>&1
DB=module-04/edge.db
run() { echo "\$ $*"; "$@"; echo "(exit code $?)"; echo; }

echo "## 1. A view exposes a safe subset for report readers"
run sqlite3 $DB "DROP VIEW IF EXISTS machine_health; CREATE VIEW machine_health AS
  SELECT s.machine_id, s.metric, MAX(r.value) AS peak, COUNT(*) AS n
  FROM sensor s JOIN reading r USING(sensor_id) GROUP BY s.machine_id, s.metric;"
run sqlite3 -header -column $DB "SELECT * FROM machine_health;"

echo "## 2. Read-only at the file level"
run chmod 444 $DB
run ls -l $DB
echo "On Windows, Git Bash's chmod 444 sets the read-only file attribute (R):"
run cmd //c attrib "module-04\edge.db"
run sqlite3 $DB "SELECT COUNT(*) FROM reading;"
run sqlite3 $DB "DELETE FROM reading;"

echo "## 3. Read-only at the connection level (file writable again)"
run chmod 644 $DB
run sqlite3 "file:$DB?mode=ro" "SELECT COUNT(*) FROM reading;"
run sqlite3 "file:$DB?mode=ro" "DELETE FROM reading;"
echo "The same with PRAGMA query_only on a normal connection:"
run sqlite3 $DB "PRAGMA query_only = ON; DELETE FROM reading;"

echo "## 4. Check: nothing was deleted"
run sqlite3 $DB "SELECT COUNT(*) FROM reading;"
