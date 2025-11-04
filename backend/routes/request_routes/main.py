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
import base64
from datetime import datetime

router = APIRouter(prefix="/requests", tags=["leave_requests"])

# Ensure archive directory exists
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
STATIC_DIR = os.path.join(BASE_DIR, 'static')
ARCHIVE_DIR = os.path.join(STATIC_DIR, 'leave_requests')
os.makedirs(ARCHIVE_DIR, exist_ok=True)

def _serialize_request(req: LeaveRequest) -> dict:
    # Convert binary image data back to Base64 for JSON serialization
    image_data_str = None
    if req.image_data:
        try:
            image_data_str = base64.b64encode(req.image_data).decode('utf-8')
        except Exception:
            image_data_str = None

    return {
        "id": req.id,
        "student_id": req.student_id,
        "start_date": req.start_date.isoformat() if req.start_date else None,
        "end_date": req.end_date.isoformat() if req.end_date else None,
        "reason": req.reason,
        "status": req.status,
        "image_data": image_data_str,  # Base64 string for JSON compatibility
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
    # Handle Base64 image data conversion
    image_bytes = None
    if request.image_data:
        try:
            # Decode Base64 string to raw bytes for database storage
            image_bytes = base64.b64decode(request.image_data)
        except Exception as e:
            # Handle decoding errors gracefully
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid image data encoding: {str(e)}"
            )

    # Create database record with decoded image bytes
    db_request = LeaveRequest(
        student_id=current_user.id,
        start_date=request.start_date,
        end_date=request.end_date,
        reason=request.reason,
        image_data=image_bytes,  # Store raw bytes, not Base64 string
        status="pending"
    )
    db.add(db_request)
    db.flush()  # Flush to get the ID before adding relationships

    # Assign advisors if provided, otherwise assign to all advisors
    if request.advisor_ids:
        advisors = db.query(User).filter(
            User.id.in_(request.advisor_ids),
            User.role == "advisor"
        ).all()
        db_request.assigned_advisors = advisors
    else:
        # If no advisors specified, assign to all advisors
        all_advisors = db.query(User).filter(User.role == "advisor").all()
        db_request.assigned_advisors = all_advisors

    db.commit()
    db.refresh(db_request)

    # Archive request to file (non-fatal if fails)
    try:
        _archive_request_to_file(db_request)
    except Exception:
        # Non-fatal - log but don't fail the request
        pass

    # Manually construct response to handle image_data serialization
    image_data_str = None
    if db_request.image_data:
        try:
            image_data_str = base64.b64encode(db_request.image_data).decode('utf-8')
        except Exception:
            pass

    advisor_ids = [advisor.id for advisor in db_request.assigned_advisors]

    return schemas.LeaveRequestOut(
        id=db_request.id,
        student_id=db_request.student_id,
        start_date=db_request.start_date,
        end_date=db_request.end_date,
        reason=db_request.reason,
        status=db_request.status,
        advisor_ids=advisor_ids,
        approved_by=db_request.approved_by,
        created_at=db_request.created_at,
        image_data=image_data_str
    )

@router.get("/me", response_model=List[schemas.LeaveRequestOut])
def get_my_requests(
    current_user: User = Depends(get_current_user_with_roles(["student"])),
    db: Session = Depends(get_db)
):
    requests = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student),
        selectinload(LeaveRequest.assigned_advisors)
    ).filter(
        LeaveRequest.student_id == current_user.id
    ).all()

    # Manually construct response for each request
    result = []
    for req in requests:
        image_data_str = None
        if req.image_data:
            try:
                image_data_str = base64.b64encode(req.image_data).decode('utf-8')
            except Exception:
                pass

        advisor_ids = [advisor.id for advisor in req.assigned_advisors]

        req_data = schemas.LeaveRequestOut(
            id=req.id,
            student_id=req.student_id,
            start_date=req.start_date,
            end_date=req.end_date,
            reason=req.reason,
            status=req.status,
            advisor_ids=advisor_ids,
            approved_by=req.approved_by,
            created_at=req.created_at,
            image_data=image_data_str
        )
        result.append(req_data)

    return result

@router.get("/pending", response_model=List[schemas.LeaveRequestOut])
def get_pending_requests(
    current_user: User = Depends(require_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    # Build base query with eager loading
    query = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student),
        selectinload(LeaveRequest.assigned_advisors)
    ).filter(
        LeaveRequest.status == "pending"
    )

    # If advisor, filter to only show requests assigned to them
    # If admin, show all pending requests
    if current_user.role == "advisor":
        # Join with the association table to filter by assigned advisor
        query = query.join(
            LeaveRequest.assigned_advisors
        ).filter(
            User.id == current_user.id
        )

    requests = query.all()

    # Manually construct response for each request to handle image_data serialization
    result = []
    for req in requests:
        # Convert image_data bytes to Base64 if present
        image_data_str = None
        if req.image_data:
            try:
                image_data_str = base64.b64encode(req.image_data).decode('utf-8')
            except Exception:
                pass

        advisor_ids = [advisor.id for advisor in req.assigned_advisors]

        req_data = schemas.LeaveRequestOut(
            id=req.id,
            student_id=req.student_id,
            start_date=req.start_date,
            end_date=req.end_date,
            reason=req.reason,
            status=req.status,
            advisor_ids=advisor_ids,
            approved_by=req.approved_by,
            created_at=req.created_at,
            image_data=image_data_str
        )
        result.append(req_data)

    return result

@router.post("/{request_id}/approve", response_model=schemas.LeaveRequestActionResponse)
def approve_request(
    request_id: str,
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    request = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.assigned_advisors)
    ).filter(LeaveRequest.id == request_id).first()
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found"
        )

    # Update request status
    request.status = "approved"
    request.approved_by = current_user.id

    # When a leave is approved, reflect as On-Duty across the requested date range
    from datetime import timedelta
    try:
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

        # Commit all changes together
        db.commit()
        db.refresh(request)

        # Archive to file
        try:
            _archive_request_to_file(request)
        except Exception:
            pass

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to approve request: {str(e)}"
        )

    # Return response without image_data to avoid serialization issues
    advisor_ids = [advisor.id for advisor in request.assigned_advisors]

    return schemas.LeaveRequestActionResponse(
        id=request.id,
        student_id=request.student_id,
        start_date=request.start_date,
        end_date=request.end_date,
        reason=request.reason,
        status=request.status,
        advisor_ids=advisor_ids,
        approved_by=request.approved_by,
        created_at=request.created_at
    )

@router.post("/{request_id}/reject", response_model=schemas.LeaveRequestActionResponse)
def reject_request(
    request_id: str,
    current_user: User = Depends(get_current_user_with_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    request = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.assigned_advisors)
    ).filter(LeaveRequest.id == request_id).first()
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found"
        )

    try:
        request.status = "rejected"
        request.approved_by = current_user.id
        db.commit()
        db.refresh(request)

        # Archive to file
        try:
            _archive_request_to_file(request)
        except Exception:
            pass

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reject request: {str(e)}"
        )

    # Return response without image_data to avoid serialization issues
    advisor_ids = [advisor.id for advisor in request.assigned_advisors]

    return schemas.LeaveRequestActionResponse(
        id=request.id,
        student_id=request.student_id,
        start_date=request.start_date,
        end_date=request.end_date,
        reason=request.reason,
        status=request.status,
        advisor_ids=advisor_ids,
        approved_by=request.approved_by,
        created_at=request.created_at
    )

@router.get("/", response_model=List[schemas.LeaveRequestOut])
def get_all_requests(
    current_user: User = Depends(require_student_data_access),
    db: Session = Depends(get_db)
):
    requests = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student),
        selectinload(LeaveRequest.assigned_advisors)
    ).all()

    # Manually construct response for each request
    result = []
    for req in requests:
        image_data_str = None
        if req.image_data:
            try:
                image_data_str = base64.b64encode(req.image_data).decode('utf-8')
            except Exception:
                pass

        advisor_ids = [advisor.id for advisor in req.assigned_advisors]

        req_data = schemas.LeaveRequestOut(
            id=req.id,
            student_id=req.student_id,
            start_date=req.start_date,
            end_date=req.end_date,
            reason=req.reason,
            status=req.status,
            advisor_ids=advisor_ids,
            approved_by=req.approved_by,
            created_at=req.created_at,
            image_data=image_data_str
        )
        result.append(req_data)

    return result

@router.get("/history", response_model=List[schemas.LeaveRequestOut])
def get_request_history(
    current_user: User = Depends(require_roles(["admin", "advisor"])),
    db: Session = Depends(get_db)
):
    """
    Get all processed (approved/rejected) leave requests.
    For advisors: returns only their assigned requests.
    For admins: returns all processed requests.
    """
    # Build base query with eager loading
    query = db.query(LeaveRequest).options(
        selectinload(LeaveRequest.student),
        selectinload(LeaveRequest.assigned_advisors)
    ).filter(
        LeaveRequest.status.in_(["approved", "rejected"])
    )

    # If advisor, filter to only show requests assigned to them
    if current_user.role == "advisor":
        query = query.join(
            LeaveRequest.assigned_advisors
        ).filter(
            User.id == current_user.id
        )

    requests = query.all()

    # Manually construct response for each request
    result = []
    for req in requests:
        image_data_str = None
        if req.image_data:
            try:
                image_data_str = base64.b64encode(req.image_data).decode('utf-8')
            except Exception:
                pass

        advisor_ids = [advisor.id for advisor in req.assigned_advisors]

        req_data = schemas.LeaveRequestOut(
            id=req.id,
            student_id=req.student_id,
            start_date=req.start_date,
            end_date=req.end_date,
            reason=req.reason,
            status=req.status,
            advisor_ids=advisor_ids,
            approved_by=req.approved_by,
            created_at=req.created_at,
            image_data=image_data_str
        )
        result.append(req_data)

    return result

@router.get("/{request_id}/image")
def get_request_image(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get the image data for a specific leave request.
    Returns the raw image bytes as a response.
    """
    from fastapi.responses import Response

    request = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found"
        )

    # Access control:
    # - Admin/attendance_incharge can view any
    # - Advisors can view requests assigned to them
    # - Students can view their own
    allowed = False

    if current_user.role in ["admin", "attendance_incharge"]:
        allowed = True
    elif current_user.role == "advisor":
        # Check if this advisor is assigned to this request
        # Need to load the assigned_advisors relationship
        from sqlalchemy.orm import selectinload
        request = db.query(LeaveRequest).options(
            selectinload(LeaveRequest.assigned_advisors)
        ).filter(LeaveRequest.id == request_id).first()

        # Check if current advisor is in the assigned list
        if any(advisor.id == current_user.id for advisor in request.assigned_advisors):
            allowed = True
    elif current_user.role == "student":
        if request.student_id == current_user.id:
            allowed = True

    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this image"
        )

    if not request.image_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No image attached to this request"
        )

    # Return raw image bytes
    return Response(
        content=request.image_data,
        media_type="image/jpeg"
    )

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
