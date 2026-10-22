"""Throw the legacy defects at the contract and see which guard stops each one.

Run from the repo root:  uv run python module-02/contract_check.py
Guard 1 = Pydantic (the application), guard 2 = the database built from the SQLAlchemy DDL.
"""
import sqlite3
from datetime import date

from pydantic import ValidationError
from sqlalchemy import create_engine
from sqlalchemy.schema import CreateTable

from contract import Machine, MaintenanceJob, metadata


def pydantic_guard(label, model, **data):
    try:
        model(**data)
        print(f"  Pydantic  : ACCEPTED  {label}")
    except ValidationError as e:
        print(f"  Pydantic  : REJECTED  {label}: {e.errors()[0]['msg']}")


def db_guard(conn, label, sql, params):
    try:
        conn.execute(sql, params)
        print(f"  Database  : ACCEPTED  {label}")
    except sqlite3.Error as e:
        print(f"  Database  : REJECTED  {label}: {e}")


# Build the repaired schema in memory from the SQLAlchemy contract.
engine = create_engine("sqlite://")
ddl = [str(CreateTable(t).compile(engine)) for t in metadata.sorted_tables]
conn = sqlite3.connect(":memory:")
conn.execute("PRAGMA foreign_keys = ON")      # SQLite ignores foreign keys unless this is on
for stmt in ddl:
    conn.execute(stmt)

# Good data goes in first.
conn.execute("INSERT INTO machine VALUES (1, 'SN-88120', 'Gütersloh', '2019-03-11')")
conn.execute("INSERT INTO part VALUES ('P-1001', 'Ball bearing 6203', 12.50)")
conn.execute("INSERT INTO part VALUES ('P-1003', 'Coolant filter', 9.90)")
conn.execute("INSERT INTO maint_job VALUES (1, 1, 'Beier', '2026-01-08')")

print("\nDefect 1: a job on a machine that does not exist (cnc-05 -> machine_id 5)")
pydantic_guard("machine_id=5", MaintenanceJob, job_id=3, machine_id=5, technician="Beier", done_on=date(2026, 2, 20))
db_guard(conn, "machine_id=5", "INSERT INTO maint_job VALUES (?, ?, ?, ?)", (3, 5, "Beier", "2026-02-20"))

print("\nDefect 2: the duplicate part P-1003")
db_guard(conn, "second P-1003", "INSERT INTO part VALUES (?, ?, ?)", ("P-1003", "Coolant filter", 9.90))

print("\nDefect 3: price stored as text")
conn.execute("INSERT INTO part VALUES (?, ?, ?)", ("P-1002", "Spindle belt", "48.00"))
print("  Database  : stored '48.00' as", conn.execute("SELECT typeof(unit_price) FROM part WHERE part_no='P-1002'").fetchone()[0],
      "(NUMERIC column converts it, so '9.90' < 15 now compares as money)")
print("  Database  : parts under 15 ->", conn.execute("SELECT part_no FROM part WHERE unit_price < 15 ORDER BY part_no").fetchall())

print("\nDefect 4: installed = 'unknown'")
pydantic_guard("installed='unknown'", Machine, machine_id=4, serial_no="SN-90000", site="Gütersloh", installed="unknown")
db_guard(conn, "installed='unknown'", "INSERT INTO machine VALUES (?, ?, ?, ?)", (4, "SN-90000", "Gütersloh", "unknown"))

print("\nDefect 5: two parts in one job, now as two rows in the junction table")
conn.execute("INSERT INTO job_part VALUES (1, 'P-1001')")
conn.execute("INSERT INTO job_part VALUES (1, 'P-1002')")
print("  Database  : job 1 parts ->", conn.execute(
    "SELECT jp.job_id, p.description FROM job_part jp JOIN part p ON p.part_no = jp.part_no ORDER BY 2").fetchall())
db_guard(conn, "job 1 lists P-1001 twice", "INSERT INTO job_part VALUES (?, ?)", (1, "P-1001"))
db_guard(conn, "a part that does not exist", "INSERT INTO job_part VALUES (?, ?)", (1, "P-9999"))

print("\nExtra rule: serial numbers must start with 'SN-'")
pydantic_guard("serial_no='88123'", Machine, machine_id=5, serial_no="88123", site="Bielefeld", installed=date(2021, 7, 2))
db_guard(conn, "serial_no='88123'", "INSERT INTO machine VALUES (?, ?, ?, ?)", (5, "88123", "Bielefeld", "2021-07-02"))
db_guard(conn, "serial_no repeated", "INSERT INTO machine VALUES (?, ?, ?, ?)", (6, "SN-88120", "Bielefeld", "2021-07-02"))
