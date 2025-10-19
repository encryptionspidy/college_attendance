from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime
from enum import Enum
import uuid

class UserRole(str, Enum):
    student = "student"
    faculty = "faculty"
    admin = "admin"
    advisor = "advisor"
    attendance_incharge = "attendance_incharge"

class UserBase(BaseModel):
    username: str
    role: UserRole

class UserCreate(UserBase):
    password: str
    roll_no: Optional[str] = None
    name: Optional[str] = None
    semester: Optional[int] = None
    year: Optional[int] = None
    dob: Optional[date] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    cgpa: Optional[float] = None
    course: Optional[str] = None
    section: Optional[str] = None
    profile_picture_url: Optional[str] = None

class UserLogin(BaseModel):
    username: str
    password: str

class UserOut(UserBase):
    id: str
    created_at: datetime
    roll_no: Optional[str] = None
    name: Optional[str] = None
    semester: Optional[int] = None
    year: Optional[int] = None
    dob: Optional[date] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    cgpa: Optional[float] = None
    course: Optional[str] = None
    section: Optional[str] = None
    profile_picture_url: Optional[str] = None

    class Config:
        from_attributes = True

class UserProfileUpdate(BaseModel):
    roll_no: Optional[str] = None
    name: Optional[str] = None
    semester: Optional[int] = None
    year: Optional[int] = None
    dob: Optional[date] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    cgpa: Optional[float] = None
    course: Optional[str] = None
    section: Optional[str] = None
    profile_picture_url: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    role: UserRole

class LeaveRequestBase(BaseModel):
    start_date: date
    end_date: date
    reason: str
    image_data: Optional[str] = None

class LeaveRequestCreate(LeaveRequestBase):
    pass

class LeaveRequestOut(LeaveRequestBase):
    id: str
    student_id: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class LeaveRequestUpdate(BaseModel):
    status: str

class AttendanceRecordBase(BaseModel):
    student_id: str
    date: date
    status: str

class AttendanceRecordCreate(AttendanceRecordBase):
    pass

class AttendanceRecordOut(AttendanceRecordBase):
    id: str
    marked_by: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class AttendanceMarkRequest(BaseModel):
    records: List[AttendanceRecordCreate]

class UserUpdate(BaseModel):
    username: Optional[str] = None
    role: Optional[UserRole] = None
    password: Optional[str] = None
    # Optional profile fields for admin updates
    roll_no: Optional[str] = None
    name: Optional[str] = None
    semester: Optional[int] = None
    year: Optional[int] = None
    dob: Optional[date] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    cgpa: Optional[float] = None
    course: Optional[str] = None
    section: Optional[str] = None
    profile_picture_url: Optional[str] = None
