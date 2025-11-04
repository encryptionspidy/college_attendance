# attendance_routes/marking.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import tuple_
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
	# Validate all students exist first (single query)
	student_ids = [record.student_id for record in attendance_data.records]
	existing_students = db.query(User.id).filter(User.id.in_(student_ids)).all()
	existing_student_ids = {s[0] for s in existing_students}
	
	for record_data in attendance_data.records:
		if record_data.student_id not in existing_student_ids:
			raise HTTPException(
				status_code=status.HTTP_404_NOT_FOUND,
				detail=f"Student with ID {record_data.student_id} not found"
			)
	
	# Fetch existing records in a single query
	date_student_pairs = [(r.student_id, r.date) for r in attendance_data.records]
	existing_records = db.query(AttendanceRecord).filter(
		tuple_(AttendanceRecord.student_id, AttendanceRecord.date).in_(date_student_pairs)
	).all()
	
	# Create lookup dict for existing records
	existing_map = {(r.student_id, r.date): r for r in existing_records}
	
	created_records = []
	for record_data in attendance_data.records:
		key = (record_data.student_id, record_data.date)
		if key in existing_map:
			existing_record = existing_map[key]
			existing_record.status = record_data.status
			existing_record.marked_by = current_user.id
			created_records.append(existing_record)
		else:
			db_record = AttendanceRecord(
				student_id=record_data.student_id,
				date=record_data.date,
				status=record_data.status,
				marked_by=current_user.id
			)
			db.add(db_record)
			created_records.append(db_record)
	
	db.commit()
	for record in created_records:
		db.refresh(record)
	
	return created_records
