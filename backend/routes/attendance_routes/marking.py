# attendance_routes/marking.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import schemas
from models import AttendanceRecord, User
from auth import get_current_user_with_roles, get_db, require_roles

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.post("/mark", response_model=List[schemas.AttendanceRecordOut])
def mark_attendance(
	attendance_data: schemas.AttendanceMarkRequest,
	current_user: User = Depends(require_roles(["admin", "advisor", "attendance_incharge"])),
	db: Session = Depends(get_db)
):
	created_records = []
	for record_data in attendance_data.records:
		student = db.query(User).filter(User.id == record_data.student_id).first()
		if not student:
			raise HTTPException(
				status_code=status.HTTP_404_NOT_FOUND,
				detail=f"Student with ID {record_data.student_id} not found"
			)
		existing_record = db.query(AttendanceRecord).filter(
			AttendanceRecord.student_id == record_data.student_id,
			AttendanceRecord.date == record_data.date
		).first()
		if existing_record:
			existing_record.status = record_data.status
			existing_record.marked_by = current_user.id
			db.commit()
			db.refresh(existing_record)
			created_records.append(existing_record)
		else:
			db_record = AttendanceRecord(
				student_id=record_data.student_id,
				date=record_data.date,
				status=record_data.status,
				marked_by=current_user.id
			)
			db.add(db_record)
			db.commit()
			db.refresh(db_record)
			created_records.append(db_record)
	return created_records
