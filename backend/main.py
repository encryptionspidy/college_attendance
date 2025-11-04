from dotenv import load_dotenv

# Load environment variables FIRST, before any other imports
load_dotenv()

from fastapi import FastAPI, Depends, Request, UploadFile, File, HTTPException, status
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from routes import auth
from routes.users import router as users_router
from routes.attendance_routes.marking import router as attendance_marking_router
from routes.attendance_routes.retrieval import router as attendance_retrieval_router
from routes.attendance_routes.holidays import router as attendance_holidays_router
from routes.request_routes.main import router as request_routes_router
from database import engine, Base, get_db
from sqlalchemy.orm import Session
from auth import get_current_user
from models import User
import os
import shutil
from logging_config import logger
import time
from contextlib import asynccontextmanager

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Starting College Attendance Marker API...")

    # Ensure tables exist
    Base.metadata.create_all(bind=engine)
    logger.info("✅ Database tables verified")
    
    yield
    
    # Shutdown
    logger.info("👋 Shutting down College Attendance Marker API...")

app = FastAPI(
    title="College Attendance Marker API", 
    version="1.0.0",
    docs_url="/docs" if os.getenv("ENVIRONMENT") != "production" else None,
    redoc_url="/redoc" if os.getenv("ENVIRONMENT") != "production" else None,
    lifespan=lifespan
)

# Add rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    # Log slow requests
    if process_time > 1.0:  # Log requests taking more than 1 second
        logger.warning(f"Slow request: {request.method} {request.url.path} took {process_time:.2f}s")
    
    return response

# Add error logging middleware
@app.middleware("http")
async def log_errors(request: Request, call_next):
    try:
        response = await call_next(request)
        return response
    except Exception as e:
        logger.error(f"Unhandled error in {request.method} {request.url.path}: {str(e)}", exc_info=True)
        raise

# Add CORS middleware for Flutter app
# Security: Configure allowed origins based on environment
ALLOWED_ORIGINS_ENV = os.getenv("ALLOWED_ORIGINS", "")
if ALLOWED_ORIGINS_ENV:
    ALLOWED_ORIGINS = [origin.strip() for origin in ALLOWED_ORIGINS_ENV.split(",") if origin.strip()]
    logger.info(f"✅ CORS configured for origins: {ALLOWED_ORIGINS}")
else:
    # Development mode - allow all origins but warn
    ALLOWED_ORIGINS = ["*"]
    logger.warning("⚠️ WARNING: CORS allows all origins. Set ALLOWED_ORIGINS in production.")
    logger.warning("   Example: export ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Add GZip compression for faster response times (only compress responses > 500 bytes)
app.add_middleware(GZipMiddleware, minimum_size=500, compresslevel=6)

# Add Trusted Host middleware for production
if os.getenv("ENVIRONMENT") == "production":
    TRUSTED_HOSTS = os.getenv("TRUSTED_HOSTS", "localhost").split(",")
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=TRUSTED_HOSTS)

# Public router: authentication (no global auth dependency)
app.include_router(auth.router, prefix="/auth", tags=["authentication"])

# Protected routers: require authenticated user by default
app.include_router(users_router, dependencies=[Depends(get_current_user)])
app.include_router(request_routes_router, dependencies=[Depends(get_current_user)])
app.include_router(attendance_marking_router, dependencies=[Depends(get_current_user)])
app.include_router(attendance_retrieval_router, dependencies=[Depends(get_current_user)])
app.include_router(attendance_holidays_router, dependencies=[Depends(get_current_user)])

# Serve static files (e.g., uploaded profile pictures)
static_dir = os.path.join(os.path.dirname(__file__), 'static')
uploads_dir = os.path.join(static_dir, 'uploads')
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")

@app.post("/users/me/upload-profile-picture", status_code=200, tags=["users"])
async def upload_profile_picture(
    file: UploadFile = File(...),
    db = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Validate file size (max 5MB)
    MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
    file_content = await file.read()
    if len(file_content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File size exceeds 5MB limit"
        )
    
    # Validate file type
    ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    file_extension = os.path.splitext(file.filename)[1].lower()
    if file_extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    # Sanitize filename and create a unique path
    # Using user ID ensures that each user has a unique, predictable image name
    filename = f"user_{current_user.id}{file_extension}"
    file_path = os.path.join(uploads_dir, filename)

    # Save the file
    try:
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)
        logger.info(f"Profile picture uploaded for user {current_user.id}: {filename}")
    except Exception as e:
        logger.error(f"Failed to save profile picture for user {current_user.id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Could not save file")

    # Update the user's profile picture URL in the database
    # The URL should be the relative path that the client can request
    file_url = f"/static/uploads/{filename}"
    
    user_to_update = db.query(User).filter(User.id == current_user.id).first()
    if not user_to_update:
        raise HTTPException(status_code=404, detail="User not found")
        
    user_to_update.profile_picture_url = file_url
    db.commit()

    return {"profile_picture_url": file_url}


@app.get("/")
def read_root():
    return {"message": "College Attendance Marker API is running", "version": "1.0.0"}

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    """Health check endpoint for monitoring"""
    try:
        # Check database connection
        db.execute("SELECT 1")
        return {
            "status": "healthy",
            "database": "connected",
            "version": "1.0.0"
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service unavailable"
        )
