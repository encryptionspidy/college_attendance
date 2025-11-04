"""
Add missing columns to users table
Run this to fix database schema mismatches
"""
import sqlite3
import sys

def migrate_database():
    try:
        conn = sqlite3.connect('college_attendance.db')
        cursor = conn.cursor()

        # List of columns to add (column_name, data_type)
        columns_to_add = [
            ('age', 'INTEGER'),
            ('department', 'VARCHAR(100)'),
            ('employee_id', 'VARCHAR(20)'),
            ('phone', 'VARCHAR(15)'),
            ('email', 'VARCHAR(100)'),
        ]

        # Get existing columns
        cursor.execute("PRAGMA table_info(users)")
        existing_columns = {row[1] for row in cursor.fetchall()}

        # Add missing columns
        for column_name, data_type in columns_to_add:
            if column_name not in existing_columns:
                try:
                    cursor.execute(f"ALTER TABLE users ADD COLUMN {column_name} {data_type}")
                    print(f"✓ Added column: {column_name}")
                except sqlite3.OperationalError as e:
                    if "duplicate column name" not in str(e).lower():
                        print(f"✗ Error adding {column_name}: {e}")
            else:
                print(f"○ Column {column_name} already exists")

        conn.commit()
        conn.close()

        print("\n✅ Database migration completed successfully!")
        return True

    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        return False

if __name__ == "__main__":
    success = migrate_database()
    sys.exit(0 if success else 1)

