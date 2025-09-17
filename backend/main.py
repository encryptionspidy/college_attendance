from fastapi import FastAPI, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from routes import auth
from routes.users import router as users_router
from routes.attendance_routes.marking import router as attendance_marking_router
from routes.attendance_routes.retrieval import router as attendance_retrieval_router
from routes.attendance_routes.holidays import router as attendance_holidays_router
from routes.request_routes.main import router as request_routes_router
from database import engine, Base
from auth import get_current_user

app = FastAPI(title="College Attendance Marker API", version="1.0.0")

# Run lightweight migration and ensure tables exist at startup
@app.on_event("startup")
def _startup_migration_and_create():
    try:
        from migrate_db import migrate_database
        migrate_database()
    except Exception as e:
        # Avoid crashing if migration fails; logs will show the error
        print(f"Startup migration skipped due to error: {e}")
    # Ensure tables (no-op if they already exist)
    Base.metadata.create_all(bind=engine)

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Public router: authentication (no global auth dependency)
app.include_router(auth.router, tags=["authentication"])  # contains POST /token

# Protected routers: require authenticated user by default
app.include_router(users_router, dependencies=[Depends(get_current_user)])
app.include_router(request_routes_router, dependencies=[Depends(get_current_user)])
app.include_router(attendance_marking_router, dependencies=[Depends(get_current_user)])
app.include_router(attendance_retrieval_router, dependencies=[Depends(get_current_user)])
app.include_router(attendance_holidays_router, dependencies=[Depends(get_current_user)])

# Serve static files (e.g., uploaded profile pictures)
import os
from fastapi import UploadFile, File, HTTPException
from database import get_db
from models import User
import shutil

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
    # Sanitize filename and create a unique path
    # Using user ID ensures that each user has a unique, predictable image name
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"user_{current_user.id}{file_extension}"
    file_path = os.path.join(uploads_dir, filename)

    # Save the file
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {e}")

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
    return {"message": "College Attendance Marker API is running"}
