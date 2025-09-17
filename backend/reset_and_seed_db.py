
import asyncio
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
import bcrypt
import os
from datetime import date # Import date object

# It's a good practice to use a configuration file for database URLs
# but for this script, we'll define it directly.
DATABASE_URL = "sqlite:///./college_attendance.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def hash_password(password: str) -> str:
    """Hashes the password using bcrypt."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

import asyncio
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
import bcrypt
import os
from datetime import date

# It's a good practice to use a configuration file for database URLs
# but for this script, we'll define it directly.
DATABASE_URL = "sqlite:///./college_attendance.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def hash_password(password: str) -> str:
    """Hashes the password using bcrypt."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

async def reset_and_seed_database():
    """
    Resets the database by clearing specified tables and seeds it with new data.
    """
    db = SessionLocal()
    try:
        print("Starting database reset and seed process...")

        # Use ORM for safety and consistency
        from models import User, LeaveRequest, AttendanceRecord

        # 1. Delete from leave_requests
        print("Deleting from leave_requests...")
        db.query(LeaveRequest).delete()
        print("Done.")

        # 2. Delete from attendance_records
        print("Deleting from attendance_records...")
        db.query(AttendanceRecord).delete()
        print("Done.")

        # 3. Delete all users except 'admin'
        print("Deleting non-admin users...")
        db.query(User).filter(User.role != 'admin').delete()
        print("Done.")

        # Commit deletions before adding new data
        db.commit()

        # 4. Create 60 new Student users
        print("Creating 60 new Student users...")
        hashed_password = hash_password("12345678")
        new_students = []
        for i in range(1, 61):
            username = f"23CS{i:03d}"
            new_students.append(User(
                username=username,
                hashed_password=hashed_password,
                role='student',
                name=f"Student {i:03d}",
                roll_no=username,
                semester=1,
                year=1,
                dob=date(2000, 1, 1),
                gender='Male',
                cgpa=0.0,
                course='B.Tech',
                section='A',
                profile_picture_url=''
            ))
        db.add_all(new_students)
        print("Done.")

        # 5. Create 5 new Advisor users
        print("Creating 5 new Advisor users...")
        new_advisors = []
        for i in range(1, 6):
            new_advisors.append(User(
                username=f"advisor{i}",
                hashed_password=hashed_password,
                role='advisor',
                name=f"Advisor {i}",
                profile_picture_url=''
            ))
        db.add_all(new_advisors)
        print("Done.")

        # 6. Create 1 new Attendance Incharge user
        print("Creating 1 new Attendance Incharge user...")
        attendance_incharge = User(
            username="attendance_incharge",
            hashed_password=hashed_password,
            role='attendance_incharge',
            name="Attendance Incharge",
            profile_picture_url=''
        )
        db.add(attendance_incharge)
        print("Done.")

        db.commit()
        print("\nDatabase has been successfully reset and seeded with new data.")

    except Exception as e:
        print(f"An error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    # This allows running the script directly
    # Note: FastAPI's async nature means we should ideally use an async main function.
    # For simplicity in this script, we'll use asyncio.run().
    print("Running seeding script...")
    asyncio.run(reset_and_seed_database())
    print("Seeding script finished.")
