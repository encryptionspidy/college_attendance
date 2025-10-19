import asyncio
from datetime import date
from sqlalchemy.orm import Session

# Use the same DB/session and password hashing as the main app to avoid mismatch
from database import SessionLocal
from auth import get_password_hash

async def reset_and_seed_database():
    """
    Resets the database by clearing specified tables and seeds it with new data.
    """
    db: Session = SessionLocal()
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

        # 3. Delete all users except 'admin' (keep admin if exists)
        print("Deleting non-admin users...")
        db.query(User).filter(User.role != 'admin').delete()
        print("Done.")

        # Commit deletions before adding new data
        db.commit()

        # 4. Ensure an admin exists
        print("Ensuring admin user exists...")
        admin = db.query(User).filter(User.username == "admin").first()
        if not admin:
            admin = User(
                username="admin",
                hashed_password=get_password_hash("admin123"),
                role='admin',
                name='Administrator'
            )
            db.add(admin)
            db.commit()
            print("Created admin user: admin / admin123")
        else:
            print("Admin user already present.")

        # 5. Create 60 new Student users
        print("Creating 60 new Student users...")
        hashed_password = get_password_hash("12345678")
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

        # 6. Create 5 new Advisor users
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

        # 7. Create 1 new Attendance Incharge user
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
        print("\n⚠️  WARNING: The following credentials are for DEVELOPMENT use only!")
        print("\nLogin credentials:")
        print("  Admin:           admin / admin123")
        print("  Advisors:        advisor1..advisor5 / 12345678")
        print("  Attendance Incharge: attendance_incharge / 12345678")
        print("  Students:        23CS001..23CS060 / 12345678")

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
