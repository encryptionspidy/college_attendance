#!/bin/bash
# College Attendance Marker - Backend Startup Script

set -e  # Exit on error

echo "===================================="
echo "Starting Backend Server"
echo "===================================="

# Navigate to backend directory
cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    echo "Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "✓ Virtual environment found"
    source venv/bin/activate
fi

# Check if database exists
if [ ! -f "college_attendance.db" ]; then
    echo "❌ Database not found!"
    echo "Initializing database..."
    export SECRET_KEY="dev-secret-key-change-in-production"
    python force_init_db.py
    echo "✓ Database initialized"
else
    echo "✓ Database found"
fi

# Set environment variables
export SECRET_KEY=${SECRET_KEY:-"dev-secret-key-change-in-production"}

echo ""
echo "===================================="
echo "Backend Server Configuration"
echo "===================================="
echo "Host: 0.0.0.0"
echo "Port: 8000"
echo "API Docs: http://localhost:8000/docs"
echo "===================================="
echo ""

# Start the server
echo "Starting Uvicorn server..."
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

