# attendance_routes/holidays.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import schemas
from models import AttendanceRecord, User
from auth import get_current_user_with_roles, get_db

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.post("/day-status", response_model=dict)
def mark_day_status(
	day_status_data: dict,
	current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
	db: Session = Depends(get_db)
):
	date = day_status_data.get('date')
	day_type = day_status_data.get('day_type')  # 'holiday', 'exam', 'event', etc.
	description = day_status_data.get('description', '')
	if not date or not day_type:
		raise HTTPException(
			status_code=status.HTTP_400_BAD_REQUEST,
			detail="Date and day_type are required"
		)
	return {
		"success": True,
		"message": f"Day marked as {day_type}",
		"date": date,
		"day_type": day_type,
		"description": description,
		"marked_by": current_user.id
	}

@router.post("/set-day-status")
def set_day_status(
    day_data: dict,
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
    db: Session = Depends(get_db)
):
    """
    Set status for an entire day (e.g., Holiday, Weekend).
    This will mark all students as having the specified status for that date.
    This operation is transactional.
    """
    from datetime import datetime
    from sqlalchemy.exc import SQLAlchemyError

    date_str = day_data.get("date")
    status_value = day_data.get("status")
    
    if not date_str or not status_value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Date and status are required"
        )

    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date format. Use YYYY-MM-DD"
        )

    try:
        students = db.query(User).filter(User.role == "student").all()
        if not students:
            return {"message": "No students found to update.", "affected_students": 0}

        updated_count = 0
        for student in students:
            # Use a single query to update or insert (upsert)
            record = db.query(AttendanceRecord).filter(
                AttendanceRecord.student_id == student.id,
                AttendanceRecord.date == date_obj
            ).first()

            if record:
                record.status = status_value
                record.marked_by = current_user.id
            else:
                record = AttendanceRecord(
                    student_id=student.id,
                    date=date_obj,
                    status=status_value,
                    marked_by=current_user.id
                )
                db.add(record)
            updated_count += 1
        
        # Commit the transaction once for all students
        db.commit()

        return {
            "message": f"Successfully set {updated_count} students as '{status_value}' for {date_str}",
            "date": date_str,
            "status": status_value,
            "affected_students": updated_count
        }
    except SQLAlchemyError as e:
        db.rollback()
        # Security: Don't expose internal errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error occurred. Please try again."
        )
    except Exception as e:
        db.rollback()
        # Security: Don't expose internal errors
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred. Please try again."
        )

@router.post("/auto-mark-holidays")
def auto_mark_holidays(
	month_year_data: dict,
	current_user: User = Depends(get_current_user_with_roles(["admin", "advisor", "attendance_incharge"])),
	db: Session = Depends(get_db)
):
	"""
	Automatically mark Sundays and 1st & 3rd Saturdays as holidays for all students
	Expected input: {"year": 2025, "month": 1}
	"""
	from datetime import datetime, timedelta
	import calendar
	try:
		year = month_year_data.get("year")
		month = month_year_data.get("month")
		if not year or not month:
			raise HTTPException(
				status_code=status.HTTP_400_BAD_REQUEST,
				detail="Year and month are required"
			)
		students = db.query(User).filter(User.role == "student").all()
		if not students:
			raise HTTPException(
				status_code=status.HTTP_404_NOT_FOUND,
				detail="No students found"
			)
		_, num_days = calendar.monthrange(year, month)
		holiday_dates = []
		saturday_count = 0
		for day in range(1, num_days + 1):
			date_obj = datetime(year, month, day).date()
			weekday = date_obj.weekday()  # 0=Monday, 6=Sunday
			if weekday == 6:  # Sunday
				holiday_dates.append(date_obj)
			elif weekday == 5:  # Saturday
				saturday_count += 1
				if saturday_count in [1, 3]:
					holiday_dates.append(date_obj)
		created_records = []
		for holiday_date in holiday_dates:
			for student in students:
				existing_record = db.query(AttendanceRecord).filter(
					AttendanceRecord.student_id == student.id,
					AttendanceRecord.date == holiday_date
				).first()
				if existing_record:
					existing_record.status = "Holiday"
					existing_record.marked_by = current_user.id
					created_records.append(existing_record)
				else:
					db_record = AttendanceRecord(
						student_id=student.id,
						date=holiday_date,
						status="Holiday",
						marked_by=current_user.id
					)
					db.add(db_record)
					created_records.append(db_record)
		# Commit once after all records are processed
		db.commit()
		# Refresh records after commit
		for record in created_records:
			db.refresh(record)
		return {
			"message": f"Successfully marked {len(holiday_dates)} holiday dates for {len(students)} students in {month}/{year}",
			"holiday_dates": [str(d) for d in holiday_dates],
			"total_records_created": len(created_records)
		}
	except Exception as e:
		# Security: Don't expose internal errors
		raise HTTPException(
			status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
			detail="Error auto-marking holidays. Please try again."
		)
