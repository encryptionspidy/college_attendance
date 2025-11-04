import sqlite3
import os
DB_PATH = os.path.join(os.path.dirname(__file__), 'college_attendance.db')
def migrate_database():
    print("Starting database migration...")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("PRAGMA table_info(leave_requests)")
        columns = [col[1] for col in cursor.fetchall()]
        if 'assigned_to' not in columns:
            print("Adding 'assigned_to' column...")
            cursor.execute("ALTER TABLE leave_requests ADD COLUMN assigned_to TEXT")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_leave_assigned_to ON leave_requests(assigned_to)")
            print("Added 'assigned_to' column")
        else:
            print("'assigned_to' column already exists")
        if 'approved_by' not in columns:
            print("Adding 'approved_by' column...")
            cursor.execute("ALTER TABLE leave_requests ADD COLUMN approved_by TEXT")
            print("Added 'approved_by' column")
        else:
            print("'approved_by' column already exists")
        conn.commit()
        print("Migration completed successfully!")
    except Exception as e:
        print(f"Migration failed: {e}")
        conn.rollback()
        raise
    finally:
        conn.close()
if __name__ == "__main__":
    migrate_database()
