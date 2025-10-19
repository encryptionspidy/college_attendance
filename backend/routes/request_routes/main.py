from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, selectinload
from typing import List
import schemas
from models import LeaveRequest, User, AttendanceRecord
from auth import (
    get_current_user, get_db,
    get_current_user_with_roles,
    require_student_data_access, require_roles
)
import os
import json
from datetime import datetime

router = APIRouter(prefix="/requests", tags=["leave_requests"])

# Ensure archive directory exists
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
STATIC_DIR = os.path.join(BASE_DIR, 'static')
ARCHIVE_DIR = os.path.join(STATIC_DIR, 'leave_requests')
os.makedirs(ARCHIVE_DIR, exist_ok=True)

def _serialize_request(req: LeaveRequest) -> dict:
    return {
        "id": req.id,
        "student_id": req.student_id,
        "start_date": req.start_date.isoformat() if req.start_date else None,
        "end_date": req.end_date.isoformat() if req.end_date else None,
        "reason": req.reason,
        "status": req.status,
        "image_data": req.image_data,
        "created_at": req.created_at.isoformat() if req.created_at else None,
        "exported_at": datetime.utcnow().isoformat() + 'Z',
    }

def _archive_request_to_file(req: LeaveRequest) -> str:
    data = _serialize_request(req)
    file_path = os.path.join(ARCHIVE_DIR, f"{req.id}.json")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return file_path

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
    try:
        _archive_request_to_file(db_request)
    except Exception:
        # Non-fatal
        pass
    return db_request

@router.get("/me", response_model=List[schemas.LeaveRequestOut])
def get_my_requests(
    current_user: User = Depends(get_current_user_with_roles(["student"])),
    db: Session = Depends(get_db)
):
    requests = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student)
    ).filter(
        LeaveRequest.student_id == current_user.id
    ).all()
    return requests

@router.get("/pending", response_model=List[schemas.LeaveRequestOut])
def get_pending_requests(
    current_user: User = Depends(require_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    # Admin + advisor can view pending requests
    requests = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student)
    ).filter(
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
        db.refresh(request)
    except Exception:
        # Even if attendance update fails, keep approval state; re-attach and commit
        db.rollback()
        # Re-query the request to reattach it to the session
        request = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
        if request:
            request.status = "approved"
            db.commit()
            db.refresh(request)
    try:
        _archive_request_to_file(request)
    except Exception:
        pass
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
    try:
        _archive_request_to_file(request)
    except Exception:
        pass
    return request

@router.get("/", response_model=List[schemas.LeaveRequestOut])
def get_all_requests(
    current_user: User = Depends(require_student_data_access),
    db: Session = Depends(get_db)
):
    requests = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student)
    ).all()
    return requests

@router.get("/export/{request_id}")
def export_request_file(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    req = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")

    # Access control: admin/advisor can view any; student only own
    if current_user.role not in ["admin", "advisor"] and req.student_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    file_path = os.path.join(ARCHIVE_DIR, f"{request_id}.json")
    # If missing, regenerate
    if not os.path.exists(file_path):
        try:
            _archive_request_to_file(req)
        except Exception:
            raise HTTPException(status_code=500, detail="Could not generate export")

    # Return a JSON with public URL (served under /static)
    public_url = f"/static/leave_requests/{request_id}.json"
    return {"request_id": request_id, "url": public_url}

@router.get("/export-list")
def export_list(
    current_user: User = Depends(require_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    entries = []
    for fname in os.listdir(ARCHIVE_DIR):
        if fname.endswith('.json'):
            rid = fname[:-5]
            entries.append({
                "request_id": rid,
                "url": f"/static/leave_requests/{fname}",
            })
    return entries

@router.get("/export-list/me")
def export_list_me(
    current_user: User = Depends(get_current_user_with_roles(["student"])),
    db: Session = Depends(get_db)
):
    # Return exports only for current student
    results = db.query(LeaveRequest.id).filter(LeaveRequest.student_id == current_user.id).all()
    ids = {row[0] for row in results}
    entries = []
    for rid in ids:
        path = os.path.join(ARCHIVE_DIR, f"{rid}.json")
        if os.path.exists(path):
            entries.append({
                "request_id": rid,
                "url": f"/static/leave_requests/{rid}.json",
            })
    return entries
