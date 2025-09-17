#!/usr/bin/env python3
"""
Database initialization script for College Attendance Marker
Run this script to create the database tables and add sample data
"""
from database import engine, Base, SessionLocal
from models import User, LeaveRequest, AttendanceRecord
from auth import get_password_hash
from datetime import date, timedelta
import uuid

def create_tables():
    """Create all database tables"""
    Base.metadata.create_all(bind=engine)
    print("✓ Database tables created successfully")

def create_sample_users():
    """Create sample users for testing"""
    db = SessionLocal()
    try:
        # Check if users already exist
        if db.query(User).first():
            print("✓ Users already exist, skipping user creation")
            return
        
        # Create sample users
        users_data = [
            {"username": "admin", "password": "admin123", "role": "admin"},
            {"username": "advisor1", "password": "advisor123", "role": "advisor"},
            {"username": "student1", "password": "student123", "role": "student"},
            {"username": "student2", "password": "student123", "role": "student"},
        ]
        
        for user_data in users_data:
            user = User(
                username=user_data["username"],
                hashed_password=get_password_hash(user_data["password"]),
                role=user_data["role"]
            )
            db.add(user)
        
        db.commit()
        print("✓ Sample users created successfully")
        print("  - admin/admin123 (admin)")
        print("  - advisor1/advisor123 (advisor)")
        print("  - student1/student123 (student)")
        print("  - student2/student123 (student)")
        
    except Exception as e:
        db.rollback()
        print(f"✗ Error creating users: {e}")
    finally:
        db.close()

def create_sample_data():
    """Create sample leave requests and attendance records"""
    db = SessionLocal()
    try:
        # Get users
        student1 = db.query(User).filter(User.username == "student1").first()
        student2 = db.query(User).filter(User.username == "student2").first()
        admin = db.query(User).filter(User.username == "admin").first()
        
        if not all([student1, student2, admin]):
            print("✗ Users not found, cannot create sample data")
            return
        
        # Create sample leave requests
        if not db.query(LeaveRequest).first():
            leave_requests = [
                LeaveRequest(
                    student_id=student1.id,
                    start_date=date.today() + timedelta(days=1),
                    end_date=date.today() + timedelta(days=3),
                    reason="Medical appointment",
                    status="pending"
                ),
                LeaveRequest(
                    student_id=student2.id,
                    start_date=date.today() + timedelta(days=5),
                    end_date=date.today() + timedelta(days=7),
                    reason="Family emergency",
                    status="approved"
                )
            ]
            
            for request in leave_requests:
                db.add(request)
            
            print("✓ Sample leave requests created")
        
        # Create sample attendance records
        if not db.query(AttendanceRecord).first():
            attendance_records = []
            for days_ago in range(1, 8):  # Last 7 days
                record_date = date.today() - timedelta(days=days_ago)
                
                # Student 1 attendance
                attendance_records.append(AttendanceRecord(
                    student_id=student1.id,
                    date=record_date,
                    status="present" if days_ago % 2 == 0 else "absent",
                    marked_by=admin.id
                ))
                
                # Student 2 attendance
                attendance_records.append(AttendanceRecord(
                    student_id=student2.id,
                    date=record_date,
                    status="present",
                    marked_by=admin.id
                ))
            
            for record in attendance_records:
                db.add(record)
            
            print("✓ Sample attendance records created")
        
        db.commit()
        
    except Exception as e:
        db.rollback()
        print(f"✗ Error creating sample data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    print("Initializing College Attendance Marker Database...")
    create_tables()
    create_sample_users()
    create_sample_data()
    print("✓ Database initialization complete!")
