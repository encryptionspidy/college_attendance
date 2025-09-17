from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import schemas
from models import LeaveRequest, User, AttendanceRecord
from auth import (
    get_current_user, get_db,
    get_current_user_with_roles,
    require_student_data_access, require_roles
)

router = APIRouter(prefix="/requests", tags=["leave_requests"])

@router.post("/", response_model=schemas.LeaveRequestOut)
def create_leave_request(
    request: schemas.LeaveRequestCreate,
    current_user: User = Depends(get_current_user_with_roles(["student"])),
    db: Session = Depends(get_db)
):
    db_request = LeaveRequest(
        student_id=current_user.id,
        start_date=request.start_date,
        end_date=request.end_date,
        reason=request.reason,
        image_data=request.image_data,
        status="pending"
    )
    db.add(db_request)
    db.commit()
    db.refresh(db_request)
    return db_request

@router.get("/me", response_model=List[schemas.LeaveRequestOut])
def get_my_requests(
    current_user: User = Depends(get_current_user_with_roles(["student"])),
    db: Session = Depends(get_db)
):
    requests = db.query(LeaveRequest).filter(
        LeaveRequest.student_id == current_user.id
    ).all()
    return requests

@router.get("/pending", response_model=List[schemas.LeaveRequestOut])
def get_pending_requests(
    current_user: User = Depends(require_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    # Admin + advisor can view pending requests
    requests = db.query(LeaveRequest).filter(
        LeaveRequest.status == "pending"
    ).all()
    return requests

@router.post("/{request_id}/approve", response_model=schemas.LeaveRequestOut)
def approve_request(
    request_id: str,
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    request = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found"
        )
    request.status = "approved"
    # When a leave is approved, reflect as On-Duty across the requested date range
    try:
        from datetime import timedelta
        current_date = request.start_date
        while current_date <= request.end_date:
            existing = db.query(AttendanceRecord).filter(
                AttendanceRecord.student_id == request.student_id,
                AttendanceRecord.date == current_date
            ).first()
            if existing:
                existing.status = "On-Duty"
                existing.marked_by = current_user.id
            else:
                db.add(AttendanceRecord(
                    student_id=request.student_id,
                    date=current_date,
                    status="On-Duty",
                    marked_by=current_user.id,
                ))
            current_date += timedelta(days=1)
        db.commit()
    except Exception:
        # Even if attendance update fails, keep approval state; surface error via logs only
        db.rollback()
        request.status = "approved"
        db.commit()
    db.refresh(request)
    return request

@router.post("/{request_id}/reject", response_model=schemas.LeaveRequestOut)
def reject_request(
    request_id: str,
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    request = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found"
        )
    request.status = "rejected"
    db.commit()
    db.refresh(request)
    return request

@router.get("/", response_model=List[schemas.LeaveRequestOut])
def get_all_requests(
    current_user: User = Depends(require_student_data_access),
    db: Session = Depends(get_db)
):
    requests = db.query(LeaveRequest).all()
    return requests
