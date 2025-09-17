#!/usr/bin/env bash
set -euo pipefail

# Always run from the backend folder
cd "$(dirname "$0")/backend"

# Pin DATABASE_URL to backend-local SQLite file to avoid cwd confusion
export DATABASE_URL="sqlite:///$(pwd)/college_attendance.db"
echo "Using DATABASE_URL=$DATABASE_URL"

# Run lightweight migration to ensure columns exist
python3 migrate_db.py

# Start FastAPI with reload for dev
python3 run_server.py
