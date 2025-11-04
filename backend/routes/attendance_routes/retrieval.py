# attendance_routes/retrieval.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, selectinload
from typing import List, Optional
import schemas
from models import AttendanceRecord, User
from auth import get_current_user, get_db, get_current_user_with_roles
from logging_config import logger
from datetime import datetime

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.get("/students/{student_id}", response_model=List[schemas.AttendanceRecordOut])
def get_student_attendance(
    student_id: str,
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=500, description="Max records to return"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Role-based access control
    allowed_roles = ["admin", "advisor", "attendance_incharge"]
    if current_user.role not in allowed_roles and current_user.id != student_id:
        logger.warning(f"Unauthorized attendance access attempt by user {current_user.id} for student {student_id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to view this student's attendance"
        )

    student = db.query(User).filter(User.id == student_id).first()
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found"
        )
    
    records = db.query(AttendanceRecord).options(
        selectinload(AttendanceRecord.student),
        selectinload(AttendanceRecord.marker)
    ).filter(
        AttendanceRecord.student_id == student_id
    ).order_by(
        AttendanceRecord.date.desc()
    ).offset(skip).limit(limit).all()
    
    return records

@router.get("/me", response_model=List[schemas.AttendanceRecordOut])
def get_my_attendance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get attendance records for the current logged-in student"""
    records = db.query(AttendanceRecord).options(
        selectinload(AttendanceRecord.student),
        selectinload(AttendanceRecord.marker)
    ).filter(
        AttendanceRecord.student_id == current_user.id
    ).order_by(
        AttendanceRecord.date.desc()
    ).all()

    return records

@router.get("/me/percentage")
def get_my_attendance_percentage(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get attendance percentage for the current logged-in student"""
    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.student_id == current_user.id
    ).all()

    if not records:
        return {
            "percentage": 0.0,
            "present_days": 0,
            "total_days": 0
        }

    # Exclude holidays from calculation
    non_holiday_records = [r for r in records if r.status.lower() != 'holiday']

    if not non_holiday_records:
        return {
            "percentage": 0.0,
            "present_days": 0,
            "total_days": 0
        }

    total_days = len(non_holiday_records)
    # Count both 'present' and 'on_duty'/'on-duty' as present
    present_days = sum(1 for r in non_holiday_records
                      if r.status.lower() in ['present', 'on_duty', 'on-duty'])

    # Calculate percentage (0-100 range, not 0-1)
    percentage = (present_days * 100.0 / total_days) if total_days > 0 else 0.0

    return {
        "percentage": round(percentage, 2),  # Round to 2 decimal places
        "present_days": present_days,
        "total_days": total_days
    }

@router.get("/", response_model=List[schemas.AttendanceRecordOut])
def get_all_attendance_records(
	skip: int = Query(0, ge=0, description="Number of records to skip"),
	limit: int = Query(100, ge=1, le=500, description="Max records to return"),
	current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
	db: Session = Depends(get_db)
):
	records = db.query(AttendanceRecord).options(
        selectinload(AttendanceRecord.student),
        selectinload(AttendanceRecord.marker)
    ).order_by(
        AttendanceRecord.date.desc()
    ).offset(skip).limit(limit).all()
	return records

@router.get("/roster")
def get_attendance_roster(
    date: str = Query(..., description="Date in YYYY-MM-DD format"),
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
    db: Session = Depends(get_db)
):
    """Return list of students with their attendance status for the given date.
    Used by attendance marking UI to build the roster with existing records.
    """
    try:
        date_obj = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date format. Use YYYY-MM-DD"
        )

    # Fetch all students once
    students = db.query(User).filter(User.role == "student").all()

    # Fetch existing attendance for the date in one query
    records = db.query(AttendanceRecord).filter(AttendanceRecord.date == date_obj).all()
    status_map = {r.student_id: r.status for r in records}

    # Compose response
    roster = []
    for s in students:
        roster.append({
            "id": s.id,
            "name": s.name or s.username,
            "roll_no": s.roll_no,
            "course": getattr(s, "course", None),
            "section": getattr(s, "section", None),
            "attendance": status_map.get(s.id, "Not Marked"),
        })

    return roster
