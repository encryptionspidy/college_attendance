# attendance_routes/retrieval.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import schemas
from models import AttendanceRecord, User
from auth import get_current_user, get_db, get_current_user_with_roles

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.get("/students/{student_id}", response_model=List[schemas.AttendanceRecordOut])
def get_student_attendance(
    student_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Role-based access control
    allowed_roles = ["admin", "advisor", "attendance_incharge"]
    if current_user.role not in allowed_roles and current_user.id != student_id:
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
    
    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.student_id == student_id
    ).order_by(AttendanceRecord.date.desc()).all()
    
    return records

@router.get("/", response_model=List[schemas.AttendanceRecordOut])
def get_all_attendance_records(
	current_user: User = Depends(get_current_user_with_roles(["admin", "advisor"])),
	db: Session = Depends(get_db)
):
	records = db.query(AttendanceRecord).order_by(AttendanceRecord.date.desc()).all()
	return records
