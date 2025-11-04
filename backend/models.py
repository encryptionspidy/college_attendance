from sqlalchemy import Column, String, Date, ForeignKey, Text, DateTime, Integer, Float, Index, LargeBinary, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import uuid

# Association table for many-to-many relationship between requests and advisors
request_advisors = Table(
    'request_advisors',
    Base.metadata,
    Column('request_id', String, ForeignKey('leave_requests.id', ondelete='CASCADE'), primary_key=True),
    Column('advisor_id', String, ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
    Index('idx_request_advisors_request', 'request_id'),
    Index('idx_request_advisors_advisor', 'advisor_id'),
)

class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        Index('idx_user_role', 'role'),
        Index('idx_user_roll_no', 'roll_no'),
        Index('idx_user_section_year', 'section', 'year'),
    )
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    username = Column(String(64), unique=True, index=True, nullable=False)
    hashed_password = Column(String(128), nullable=False)
    role = Column(String(16), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # New fields for student profile
    roll_no = Column(String(20), nullable=True, unique=True)
    name = Column(String(100), nullable=True, index=True)  # Index for search
    semester = Column(Integer, nullable=True)
    year = Column(Integer, nullable=True)
    dob = Column(Date, nullable=True)
    age = Column(Integer, nullable=True)
    cgpa = Column(Float, nullable=True)
    course = Column(String(100), nullable=True)
    section = Column(String(10), nullable=True)
    profile_picture_url = Column(String(512), nullable=True)

    # Fields for all roles
    department = Column(String(100), nullable=True)
    employee_id = Column(String(20), nullable=True)
    phone = Column(String(15), nullable=True)
    email = Column(String(100), nullable=True)

    # Relationships
    submitted_requests = relationship("LeaveRequest", foreign_keys="LeaveRequest.student_id", back_populates="student")

class LeaveRequest(Base):
    __tablename__ = "leave_requests"
    __table_args__ = (
        Index('idx_leave_request_student', 'student_id'),
        Index('idx_leave_request_status', 'status'),
        Index('idx_leave_request_dates', 'start_date', 'end_date'),
    )
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    student_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    reason = Column(Text, nullable=False)
    status = Column(String(16), nullable=False, default="pending", index=True)
    image_url = Column(String(512), nullable=True)
    image_data = Column(LargeBinary, nullable=True)
    approved_by = Column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)  # Who approved/rejected
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    student = relationship("User", foreign_keys=[student_id], back_populates="submitted_requests")
    approving_advisor = relationship("User", foreign_keys=[approved_by])
    assigned_advisors = relationship("User", secondary=request_advisors, backref="assigned_requests")

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"
    __table_args__ = (
        Index('idx_attendance_student_date', 'student_id', 'date', unique=True),
        Index('idx_attendance_date_status', 'date', 'status'),
        Index('idx_attendance_marked_by', 'marked_by'),
    )
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    student_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    date = Column(Date, nullable=False, index=True)
    status = Column(String(16), nullable=False)
    marked_by = Column(String, ForeignKey("users.id", ondelete="SET NULL"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    student = relationship("User", foreign_keys=[student_id])
    marker = relationship("User", foreign_keys=[marked_by])
