# attendance_routes/retrieval.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, selectinload
from typing import List, Optional
import schemas
from models import AttendanceRecord, User
from auth import get_current_user, get_db, get_current_user_with_roles
from logging_config import logger

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
