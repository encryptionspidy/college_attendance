from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os

# Use SQLite by default, anchored to this backend folder to avoid cwd confusion
DEFAULT_DB_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "college_attendance.db")
)
DEFAULT_DATABASE_URL = f"sqlite:///{DEFAULT_DB_PATH}"

# Allow override via env
DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DATABASE_URL)

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
