#!/usr/bin/env bash
set -euo pipefail

# Always run from the backend folder
cd "$(dirname "$0")/backend"

# Set SECRET_KEY if not already set (for development)
if [ -z "${SECRET_KEY:-}" ]; then
    export SECRET_KEY="dev-secret-key-change-for-production"
    echo "⚠️  Using default development SECRET_KEY"
fi

# Pin DATABASE_URL to backend-local SQLite file to avoid cwd confusion
export DATABASE_URL="sqlite:///$(pwd)/college_attendance.db"
echo "Using DATABASE_URL=$DATABASE_URL"

# Run lightweight migration to ensure columns exist
python3 migrate_db.py

# Start FastAPI with reload for dev
python3 run_server.py
