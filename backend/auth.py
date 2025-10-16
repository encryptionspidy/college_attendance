from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from models import User
from database import SessionLocal
import schemas
import uuid
from typing import List, Callable
import os
import secrets

# Security: Use environment variable or generate secure key
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    # Generate a secure random key if not set
    SECRET_KEY = secrets.token_urlsafe(32)
    print("⚠️ WARNING: SECRET_KEY not set in environment. Using generated key.")
    print(f"   For production, set: export SECRET_KEY={SECRET_KEY}")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def authenticate_user(db: Session, username: str, password: str):
    user = db.query(User).filter(User.username == username).first()
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user

def get_current_user_with_roles(allowed_roles: List[str]) -> Callable:
    """
    Creates a dependency that checks if current user has one of the allowed roles.
    
    Usage:
        @router.get("/endpoint")
        def endpoint(user: User = Depends(get_current_user_with_roles(["admin", "advisor"]))):
            # Only admins and advisors can access this endpoint
            pass
    """
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {', '.join(allowed_roles)}. Your role: {current_user.role}"
            )
        return current_user
    return role_checker

def require_roles(allowed_roles: List[str]) -> Callable:
    """Unified flexible roles-based dependency.

    Usage in routes:
        @router.get("/resource")
        def handler(current_user: User = Depends(require_roles(["admin", "advisor"]))):
            ...

    Or:
        @router.get("/resource", dependencies=[Depends(require_roles(["admin"]))])
        async def handler(): ...
    """
    return get_current_user_with_roles(allowed_roles)

def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Dependency for admin-only endpoints"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

def require_student(current_user: User = Depends(get_current_user)) -> User:
    """Dependency for student-only endpoints"""
    if current_user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Student access required"
        )
    return current_user

def require_staff(current_user: User = Depends(get_current_user)) -> User:
    """Dependency for staff (non-student) endpoints"""
    if current_user.role not in ["admin", "advisor", "attendance_incharge"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Staff access required (admin, advisor, or attendance_incharge)"
        )
    return current_user

def require_attendance_marker(current_user: User = Depends(get_current_user)) -> User:
    """Dependency for users who can mark attendance"""
    if current_user.role not in ["admin", "advisor", "attendance_incharge"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins, advisors, and attendance incharges can mark attendance"
        )
    return current_user

def require_student_data_access(current_user: User = Depends(get_current_user)) -> User:
    """Dependency for users who can access student data"""
    if current_user.role not in ["admin", "advisor"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins and advisors can access student data"
        )
    return current_user

@router.post("/token", response_model=schemas.Token)
def login_for_access_token(form_data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    access_token = create_access_token(data={"sub": user.username, "role": user.role})
    return {"access_token": access_token, "token_type": "bearer", "role": user.role}
