#!/usr/bin/env python3
"""Force create and seed the database"""
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("=" * 80)
print("DATABASE INITIALIZATION SCRIPT")
print("=" * 80)

try:
    print("\n1. Importing modules...")
    from database import Base, engine, SessionLocal
    from models import User, LeaveRequest, AttendanceRecord
    from auth import get_password_hash
    from datetime import date

    print(f"✓ Imports successful")
    print(f"✓ Database URL: {engine.url}")

    print("\n2. Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("✓ Tables created")

    print("\n3. Creating users...")
    db = SessionLocal()
    try:
        # Create admin
        admin = db.query(User).filter(User.username == "admin").first()
        if not admin:
            admin = User(
                username="admin",
                hashed_password=get_password_hash("admin123"),
                role="admin",
                name="Administrator"
            )
            db.add(admin)
            db.commit()
            print("✓ Admin created: admin/admin123")
        else:
            print("✓ Admin already exists")

        # Create advisors
        advisor_count = 0
        for i in range(1, 5):
            advisor = db.query(User).filter(User.username == f"advisor{i}").first()
            if not advisor:
                advisor = User(
                    username=f"advisor{i}",
                    hashed_password=get_password_hash("1234"),
                    role="advisor",
                    name=f"Dr. Advisor {i}"
                )
                db.add(advisor)
                advisor_count += 1
        if advisor_count > 0:
            db.commit()
            print(f"✓ Created {advisor_count} advisors: advisor1-4 / 1234")
        else:
            print("✓ Advisors already exist")

        # Create students
        student_count = 0
        for i in range(1, 61):
            username = f"23CS{i:03d}"
            student = db.query(User).filter(User.username == username).first()
            if not student:
                student = User(
                    username=username,
                    hashed_password=get_password_hash("1234"),
                    role="student",
                    name=f"Student {username}",
                    roll_no=username,
                    semester=6,
                    year=3,
                    dob=date(2005, 1, 1),
                    gender='Male' if i % 2 == 0 else 'Female',
                    cgpa=7.5 + (i % 20) * 0.1,
                    course='B.Tech Computer Science',
                    section='A' if i <= 30 else 'B'
                )
                db.add(student)
                student_count += 1
        if student_count > 0:
            db.commit()
            print(f"✓ Created {student_count} students: 23CS001-060 / 1234")
        else:
            print("✓ Students already exist")

        # Create attendance incharge
        incharge = db.query(User).filter(User.username == "attendance_i").first()
        if not incharge:
            incharge = User(
                username="attendance_i",
                hashed_password=get_password_hash("1234"),
                role="attendance_incharge",
                name="Attendance Incharge"
            )
            db.add(incharge)
            db.commit()
            print("✓ Attendance incharge created: attendance_i / 1234")
        else:
            print("✓ Attendance incharge already exists")

        # Verify
        total_users = db.query(User).count()
        advisors = db.query(User).filter(User.role == "advisor").count()
        students = db.query(User).filter(User.role == "student").count()

        print("\n" + "=" * 80)
        print("✓ DATABASE INITIALIZATION COMPLETE!")
        print("=" * 80)
        print(f"\nTotal users: {total_users}")
        print(f"  - Advisors: {advisors}")
        print(f"  - Students: {students}")
        print("\nTest Credentials:")
        print("  Admin:              admin / admin123")
        print("  Advisors:           advisor1, advisor2, advisor3, advisor4 / 1234")
        print("  Students:           23CS001 to 23CS060 / 1234")
        print("  Attendance Incharge: attendance_i / 1234")
        print("=" * 80)

    finally:
        db.close()

except Exception as e:
    print(f"\n✗ ERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

