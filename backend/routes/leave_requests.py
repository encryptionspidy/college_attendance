"""
DEPRECATED: Leave request endpoints have moved to routes/request_routes/main.py
Kept temporarily for reference; not included by app.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import schemas
from models import LeaveRequest, User
from auth import (
    get_current_user, get_db,
    get_current_user_with_roles
)
from auth import (
    require_student_data_access,
    get_current_user, get_db,
    get_current_user_with_roles
)
import uuid

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
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
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
