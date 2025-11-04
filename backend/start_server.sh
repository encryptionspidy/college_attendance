#!/bin/bash

# College Attendance Marker - Backend Startup Script
# This script sets up and starts the FastAPI backend server

cd "$(dirname "$0")"

echo "🚀 Starting College Attendance Marker Backend..."
echo ""

# Set environment variables
export SECRET_KEY="dev_secret_key_for_testing_only_change_in_production_12345"
export ALLOWED_ORIGINS="*"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python -m venv venv
    echo "✅ Virtual environment created"
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -q -r requirements.txt

# Run database seeding
echo "🌱 Seeding database..."
python reset_and_seed_db.py

echo ""
echo "✅ Backend is ready!"
echo "📊 API Documentation: http://localhost:8000/docs"
echo "🔑 Login Credentials:"
echo "   Students: 23CS001-060 / 1234"
echo "   Advisors: advisor1-4 / 1234"
echo "   Attendance: attendance_i / 1234"
echo "   Admin: admin / admin123"
echo ""
echo "🚀 Starting server..."
echo ""

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

