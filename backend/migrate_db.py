"""
Database migration: ensures new columns exist on the users table.
This script tries to migrate the SQLite DB pointed by DATABASE_URL, or
falls back to common local paths.
"""
import sqlite3
import os


def resolve_sqlite_db_path() -> str | None:
    # 1) Respect DATABASE_URL if set and is sqlite
    db_url = os.getenv("DATABASE_URL")
    if db_url and db_url.startswith("sqlite"):
        # forms: sqlite:////abs/path.db or sqlite:///relative.db
        path = db_url.split("sqlite:///", 1)[-1]
        # normalize to absolute
        if not os.path.isabs(path):
            # resolve relative to backend folder
            path = os.path.abspath(os.path.join(os.path.dirname(__file__), path))
        return path

    # 2) Default backend-local DB
    backend_db = os.path.abspath(os.path.join(os.path.dirname(__file__), "college_attendance.db"))
    if os.path.exists(backend_db):
        return backend_db

    # 3) Project root DB (if server was started from repo root)
    root_db = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "college_attendance.db"))
    if os.path.exists(root_db):
        return root_db

    return backend_db  # create here if nothing else exists


def migrate_database():
    db_path = resolve_sqlite_db_path()
    if not db_path:
        print("Could not resolve a database path for migration.")
        return

    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Ensure users table exists before altering
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                username VARCHAR(64) UNIQUE,
                hashed_password VARCHAR(128),
                role VARCHAR(16),
                created_at DATETIME
            )
            """
        )

        # Inspect current columns
        cursor.execute("PRAGMA table_info(users)")
        columns = [row[1] for row in cursor.fetchall()]

        # Desired new columns
        new_columns = [
            ("roll_no", "VARCHAR(20)"),
            ("name", "VARCHAR(100)"),
            ("semester", "INTEGER"),
            ("year", "INTEGER"),
            ("dob", "DATE"),
            ("age", "INTEGER"),
            ("gender", "VARCHAR(10)"),
            ("cgpa", "REAL"),
            ("course", "VARCHAR(100)"),
            ("section", "VARCHAR(10)"),
            ("profile_picture_url", "VARCHAR(512)")
        ]

        for column_name, column_type in new_columns:
            if column_name not in columns:
                cursor.execute(f"ALTER TABLE users ADD COLUMN {column_name} {column_type}")
                print(f"Added column: {column_name}")
            else:
                print(f"Column {column_name} already exists")

        conn.commit()
        print(f"Database migration completed successfully at {db_path}!")

    except Exception as e:
        print(f"Error during migration: {e}")
        conn.rollback()
    finally:
        conn.close()


if __name__ == "__main__":
    migrate_database()
