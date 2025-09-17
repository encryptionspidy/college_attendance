from sqlalchemy import Column, String, Date, ForeignKey, Text, DateTime, Integer, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import uuid

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    username = Column(String(64), unique=True, index=True, nullable=False)
    hashed_password = Column(String(128), nullable=False)
    role = Column(String(16), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # New fields for student profile
    roll_no = Column(String(20), nullable=True)
    name = Column(String(100), nullable=True)
    semester = Column(Integer, nullable=True)
    year = Column(Integer, nullable=True)
    dob = Column(Date, nullable=True)
    age = Column(Integer, nullable=True)
    gender = Column(String(10), nullable=True)
    cgpa = Column(Float, nullable=True)
    course = Column(String(100), nullable=True)
    section = Column(String(10), nullable=True)
    profile_picture_url = Column(String(512), nullable=True)

class LeaveRequest(Base):
    __tablename__ = "leave_requests"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    student_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"))
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    reason = Column(Text, nullable=False)
    status = Column(String(16), nullable=False, default="pending")
    image_data = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    student = relationship("User")

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    student_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"))
    date = Column(Date, nullable=False)
    status = Column(String(16), nullable=False)
    marked_by = Column(String, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    student = relationship("User", foreign_keys=[student_id])
    marker = relationship("User", foreign_keys=[marked_by])
