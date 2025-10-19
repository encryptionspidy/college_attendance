from sqlalchemy import create_engine, event, pool
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
    # SQLite-specific optimizations for production
    engine = create_engine(
        DATABASE_URL,
        connect_args={
            "check_same_thread": False,
            "timeout": 30,  # 30 second timeout for locked database
        },
        poolclass=pool.StaticPool,  # Better for SQLite with multiple threads
        pool_pre_ping=True,  # Verify connections before using
        echo=False  # Set to True for SQL debugging
    )
    
    # Enable WAL mode for better concurrent access
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_conn, connection_record):
        cursor = dbapi_conn.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA cache_size=10000")  # 10MB cache
        cursor.execute("PRAGMA temp_store=MEMORY")
        cursor.execute("PRAGMA mmap_size=30000000000")  # 30GB memory-mapped I/O
        cursor.execute("PRAGMA page_size=4096")
        cursor.close()
else:
    # PostgreSQL/MySQL configuration
    engine = create_engine(
        DATABASE_URL,
        pool_size=20,  # Connection pool size
        max_overflow=40,  # Additional connections when pool is full
        pool_pre_ping=True,
        pool_recycle=3600,  # Recycle connections after 1 hour
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency to get a DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
