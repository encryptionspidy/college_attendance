#!/usr/bin/env python3
"""
Migration script to add request_advisors association table
and migrate existing assigned_to data
"""

from sqlalchemy import create_engine, text
from database import SQLALCHEMY_DATABASE_URL
import sys

def run_migration():
    engine = create_engine(SQLALCHEMY_DATABASE_URL)

    with engine.connect() as conn:
        try:
            print("Creating request_advisors association table...")

            # Create the new association table
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS request_advisors (
                    request_id VARCHAR NOT NULL,
                    advisor_id VARCHAR NOT NULL,
                    PRIMARY KEY (request_id, advisor_id),
                    FOREIGN KEY (request_id) REFERENCES leave_requests(id) ON DELETE CASCADE,
                    FOREIGN KEY (advisor_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """))

            # Create indexes
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_request_advisors_request
                ON request_advisors(request_id)
            """))

            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_request_advisors_advisor
                ON request_advisors(advisor_id)
            """))

            # Migrate existing assigned_to data to the new table
            print("Migrating existing assigned_to data...")
            conn.execute(text("""
                INSERT INTO request_advisors (request_id, advisor_id)
                SELECT id, assigned_to
                FROM leave_requests
                WHERE assigned_to IS NOT NULL
                ON CONFLICT DO NOTHING
            """))

            # Drop the old assigned_to column
            # Note: SQLite doesn't support DROP COLUMN easily, so we'll keep it for now
            # In production with PostgreSQL, you would drop it

            conn.commit()
            print("✅ Migration completed successfully!")
            print("   - Created request_advisors table")
            print("   - Migrated existing advisor assignments")
            print("   - Created indexes")

        except Exception as e:
            conn.rollback()
            print(f"❌ Migration failed: {e}")
            sys.exit(1)

if __name__ == "__main__":
    run_migration()

