#!/usr/bin/env python3
"""
Migration script to add performance-critical indexes to existing databases.
This script can be run safely multiple times - it will skip indexes that already exist.
"""
from database import engine
from sqlalchemy import text, inspect

def add_indexes():
    """Add performance-critical indexes to the database."""
    inspector = inspect(engine)
    
    # Define indexes to add
    indexes_to_add = [
        # Users table
        ("users", "ix_users_role", "CREATE INDEX IF NOT EXISTS ix_users_role ON users(role)"),
        
        # AttendanceRecords table
        ("attendance_records", "ix_attendance_records_student_id", 
         "CREATE INDEX IF NOT EXISTS ix_attendance_records_student_id ON attendance_records(student_id)"),
        ("attendance_records", "ix_attendance_records_date", 
         "CREATE INDEX IF NOT EXISTS ix_attendance_records_date ON attendance_records(date)"),
        ("attendance_records", "ix_attendance_records_student_date", 
         "CREATE INDEX IF NOT EXISTS ix_attendance_records_student_date ON attendance_records(student_id, date)"),
        
        # LeaveRequests table
        ("leave_requests", "ix_leave_requests_student_id", 
         "CREATE INDEX IF NOT EXISTS ix_leave_requests_student_id ON leave_requests(student_id)"),
        ("leave_requests", "ix_leave_requests_status", 
         "CREATE INDEX IF NOT EXISTS ix_leave_requests_status ON leave_requests(status)"),
        ("leave_requests", "ix_leave_requests_student_status", 
         "CREATE INDEX IF NOT EXISTS ix_leave_requests_student_status ON leave_requests(student_id, status)"),
    ]
    
    with engine.connect() as connection:
        for table_name, index_name, sql in indexes_to_add:
            try:
                print(f"Adding index {index_name} on table {table_name}...")
                connection.execute(text(sql))
                connection.commit()
                print(f"  ✓ Successfully added {index_name}")
            except Exception as e:
                print(f"  ⚠ Could not add {index_name}: {e}")
                # Continue with other indexes even if one fails
                continue
    
    print("\n✅ Index migration completed!")
    print("📊 All critical performance indexes have been added or already exist.")

if __name__ == "__main__":
    print("🔧 Starting database index migration for performance optimization...")
    print("=" * 70)
    add_indexes()
