from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
import schemas
from models import User
from auth import (
    get_current_user, get_db, get_password_hash, verify_password,
    require_admin, require_student_data_access,
    get_current_user_with_roles, require_student
)
import uuid
import os
from datetime import datetime

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=schemas.UserOut)
def create_user(
    user: schemas.UserCreate,
    current_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    # Check if username already exists
    existing_user = db.query(User).filter(User.username == user.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A user with this username already exists"
        )
    
    try:
        hashed_password = get_password_hash(user.password)
        
        db_user = User(
            username=user.username,
            hashed_password=hashed_password,
            role=user.role,
            roll_no=user.roll_no,
            name=user.name,
            semester=user.semester,
            year=user.year,
            dob=user.dob,
            age=user.age,
            gender=user.gender,
            cgpa=user.cgpa,
            course=user.course,
            section=user.section,
            profile_picture_url=user.profile_picture_url,
        )
        
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        return db_user
        
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A user with this username already exists"
        )
    except Exception as e:
        db.rollback()
        # Security: Don't expose internal errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user. Please try again."
        )

@router.get("/", response_model=List[schemas.UserOut])
def get_users(
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
    db: Session = Depends(get_db)
):
    users = db.query(User).all()
    return users

@router.get("/me", response_model=schemas.UserOut)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user

@router.get("/students", response_model=List[schemas.UserOut])
def get_students(
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
    db: Session = Depends(get_db)
):
    students = db.query(User).filter(User.role == "student").all()
    return students

@router.put("/{user_id}", response_model=schemas.UserOut)
def update_user(
    user_id: str,
    user_update: schemas.UserUpdate,
    current_user: User = Depends(get_current_user_with_roles(["admin"])),
    db: Session = Depends(get_db)
):
    # Find the user to update
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Update user fields
    if user_update.username is not None:
        # Check if new username already exists (except for current user)
        existing_user = db.query(User).filter(
            User.username == user_update.username,
            User.id != user_id
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already exists"
            )
        db_user.username = user_update.username
    
    if user_update.role is not None:
        db_user.role = user_update.role
    
    if user_update.password is not None:
        db_user.hashed_password = get_password_hash(user_update.password)
    
    # Apply optional profile fields when provided
    if user_update.roll_no is not None:
        db_user.roll_no = user_update.roll_no
    if user_update.name is not None:
        db_user.name = user_update.name
    if user_update.semester is not None:
        db_user.semester = user_update.semester
    if user_update.year is not None:
        db_user.year = user_update.year
    if user_update.dob is not None:
        db_user.dob = user_update.dob
    if user_update.age is not None:
        db_user.age = user_update.age
    if user_update.gender is not None:
        db_user.gender = user_update.gender
    if user_update.cgpa is not None:
        db_user.cgpa = user_update.cgpa
    if user_update.course is not None:
        db_user.course = user_update.course
    if user_update.section is not None:
        db_user.section = user_update.section
    if user_update.profile_picture_url is not None:
        db_user.profile_picture_url = user_update.profile_picture_url
    
    db.commit()
    db.refresh(db_user)
    return db_user

@router.delete("/{user_id}")
def delete_user(
    user_id: str,
    current_user: User = Depends(get_current_user_with_roles(["admin"])),
    db: Session = Depends(get_db)
):
    # Find the user to delete
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Prevent deleting self
    if db_user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    db.delete(db_user)
    db.commit()
    return {"message": "User deleted successfully"}

@router.post("/{user_id}/upload-picture", response_model=schemas.UserOut)
def upload_profile_picture(
    user_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user_with_roles(["admin", "student", "advisor", "attendance_incharge"])),
    db: Session = Depends(get_db)
):
    """Upload a profile picture and set profile_picture_url on the user.
    Saves to backend/static/uploads and returns updated user object.
    """
    # Only allow self or admin to upload
    if current_user.role != "admin" and current_user.id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not permitted")

    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static", "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    filename = f"{user_id}_{timestamp}_{file.filename}"
    filepath = os.path.join(uploads_dir, filename)

    with open(filepath, "wb") as f:
        f.write(file.file.read())

    # For simplicity, serve via relative path; in production, use proper static hosting
    db_user.profile_picture_url = f"/static/uploads/{filename}"
    db.commit()
    db.refresh(db_user)
    return db_user

@router.put("/me/profile", response_model=schemas.UserOut)
def update_my_profile(
    profile_update: schemas.UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's profile information"""
    try:
        # Update profile fields
        if profile_update.roll_no is not None:
            current_user.roll_no = profile_update.roll_no
        if profile_update.name is not None:
            current_user.name = profile_update.name
        if profile_update.semester is not None:
            current_user.semester = profile_update.semester
        if profile_update.year is not None:
            current_user.year = profile_update.year
        if profile_update.dob is not None:
            current_user.dob = profile_update.dob
        if profile_update.age is not None:
            current_user.age = profile_update.age
        if profile_update.gender is not None:
            current_user.gender = profile_update.gender
        if profile_update.cgpa is not None:
            current_user.cgpa = profile_update.cgpa
        if profile_update.course is not None:
            current_user.course = profile_update.course
        if profile_update.section is not None:
            current_user.section = profile_update.section
        if profile_update.profile_picture_url is not None:
            current_user.profile_picture_url = profile_update.profile_picture_url
        
        db.commit()
        db.refresh(current_user)
        return current_user
        
    except Exception as e:
        db.rollback()
        # Security: Don't expose internal errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile. Please try again."
        )

@router.post("/me/change-password")
def change_my_password(
    password_data: schemas.ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Change current user's password"""
    try:
        # Verify current password
        if not verify_password(password_data.current_password, current_user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect"
            )
        
        # Update password
        current_user.hashed_password = get_password_hash(password_data.new_password)
        db.commit()
        
        return {"message": "Password changed successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        # Security: Don't expose internal errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to change password. Please try again."
        )

# Add an endpoint for students to get their attendance records
@router.get("/me/attendance", response_model=List[schemas.AttendanceRecordOut])
def get_my_attendance(
    current_user: User = Depends(get_current_user_with_roles(["student"])),
    db: Session = Depends(get_db)
):
    """Allow students to view their own attendance records"""
    from models import AttendanceRecord
    from sqlalchemy.orm import selectinload
    
    records = db.query(AttendanceRecord).options(
        selectinload(AttendanceRecord.student),
        selectinload(AttendanceRecord.marker)
    ).filter(
        AttendanceRecord.student_id == current_user.id
    ).order_by(AttendanceRecord.date.desc()).all()
    
    return records
