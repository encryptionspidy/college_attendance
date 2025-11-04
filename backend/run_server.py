#!/usr/bin/env python3
"""
Run the FastAPI server with automatic .env loading
Usage: python run_server.py [--host HOST] [--port PORT] [--no-reload]
"""
import os
import sys
import argparse
from pathlib import Path

# Ensure unbuffered output so logs stream immediately
os.environ.setdefault("PYTHONUNBUFFERED", "1")

def load_env_file(env_path: Path):
    """Load environment variables from .env file"""
    if not env_path.exists():
        print(f"⚠️  .env file not found at {env_path}", file=sys.stderr)
        return

    print(f"📄 Loading environment from {env_path}", file=sys.stderr)
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and (key not in os.environ):
            os.environ[key] = value
    print(f"✅ Environment loaded successfully", file=sys.stderr)

# Parse arguments
parser = argparse.ArgumentParser(description="Run FastAPI server with live logs")
parser.add_argument("--host", default=None, help="Host to bind (default: from .env or 0.0.0.0)")
parser.add_argument("--port", type=int, default=None, help="Port to bind (default: from .env or 8000)")
parser.add_argument("--no-reload", action="store_true", help="Disable auto-reload")
parser.add_argument("--log-level", default="info", help="Log level (debug, info, warning, error)")
args = parser.parse_args()

# Load .env file before importing main
env_path = Path(__file__).parent / ".env"
load_env_file(env_path)

# Verify SECRET_KEY is set
if not os.getenv("SECRET_KEY"):
    print("❌ ERROR: SECRET_KEY not found in .env file!", file=sys.stderr)
    print("   Please ensure backend/.env contains a valid SECRET_KEY", file=sys.stderr)
    sys.exit(1)

# Get configuration from env or args
host = args.host or os.getenv("HOST", "0.0.0.0")
port = args.port or int(os.getenv("PORT", "8000"))
reload = not args.no_reload and os.getenv("RELOAD", "true").lower() in ("true", "1", "yes")

print(f"🚀 Starting server at http://{host}:{port}", file=sys.stderr)
print(f"🔄 Auto-reload: {'enabled' if reload else 'disabled'}", file=sys.stderr)
print(f"📊 Log level: {args.log_level}", file=sys.stderr)
print(f"🌍 Environment: {os.getenv('ENVIRONMENT', 'development')}", file=sys.stderr)
print("=" * 60, file=sys.stderr)

# Import and run
import uvicorn

if __name__ == "__main__":
    try:
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            reload=reload,
            log_level=args.log_level,
            access_log=True,
        )
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user", file=sys.stderr)
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Server crashed: {e}", file=sys.stderr)
        raise
