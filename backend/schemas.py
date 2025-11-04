from pydantic import BaseModel, field_serializer
from typing import Optional, List
from datetime import date, datetime
from enum import Enum
import uuid
import base64

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
    created_at: Optional[datetime] = None
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

class LeaveRequestCreate(BaseModel):
    start_date: date
    end_date: date
    reason: str
    image_data: Optional[str] = None  # Base64 string for input
    advisor_ids: Optional[List[str]] = None  # List of advisor UUIDs to assign

class LeaveRequestOut(LeaveRequestBase):
    id: str
    student_id: str
    status: str
    advisor_ids: Optional[List[str]] = None  # List of assigned advisor IDs
    approved_by: Optional[str] = None
    created_at: datetime
    image_data: Optional[str] = None  # Override to ensure it's always a string in output

    @field_serializer('image_data')
    def serialize_image_data(self, value, _info):
        """Convert binary image data to Base64 string for JSON serialization"""
        if value is None:
            return None
        if isinstance(value, bytes):
            try:
                return base64.b64encode(value).decode('utf-8')
            except Exception:
                return None
        if isinstance(value, str):
            return value
        # For any other type, return None
        return None

    class Config:
        from_attributes = True

class LeaveRequestUpdate(BaseModel):
    status: str

class LeaveRequestActionResponse(BaseModel):
    """Simple response for approve/reject actions without image data"""
    id: str
    student_id: str
    start_date: date
    end_date: date
    reason: str
    status: str
    advisor_ids: Optional[List[str]] = None
    approved_by: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

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
