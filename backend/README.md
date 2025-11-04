# 🎓 College Attendance Marker - Backend API

FastAPI-based backend for the SIET College Attendance Management System.

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- pip

### Setup & Run

```bash
# Install dependencies
pip install -r requirements.txt

# Set required environment variables
export SECRET_KEY="your-secret-key-here"
export ALLOWED_ORIGINS="*"  # For development only

# Initialize database
python reset_and_seed_db.py

# Start server
python run_server.py
```

Server will run at: `http://0.0.0.0:8000`
API docs: `http://localhost:8000/docs`

## 🔑 Default Test Accounts

### Students (60 accounts)
- **Username:** `23CS001` through `23CS060`
- **Password:** `1234`

### Advisors (4 accounts)
- **Username:** `advisor1`, `advisor2`, `advisor3`, `advisor4`
- **Password:** `1234`

### Attendance Incharge
- **Username:** `attendance_i`
- **Password:** `1234`

### Admin
- **Username:** `admin`
- **Password:** `admin123`

## 📚 API Endpoints Overview

### 🔐 Authentication
- `POST /auth/login` - User login (returns JWT token)
- `POST /auth/register` - User registration

### 👤 Users
- `GET /users/me` - Get current user profile
- `PUT /users/me/profile` - Update own profile
- `POST /users/me/upload-profile-picture` - Upload profile picture
- `GET /users/` - List all users (Admin/Advisor/Incharge)
- `GET /users/students` - List all students (Admin/Advisor/Incharge)
- `POST /users/` - Create user (Admin only)
- `PUT /users/{id}` - Update user (Admin only)
- `DELETE /users/{id}` - Delete user (Admin only)

### 📝 Leave Requests
- `POST /requests/` - Submit leave request (Student)
- `GET /requests/me` - Get my requests (Student)
- `GET /requests/pending` - Get pending requests (Admin/Advisor)
- `GET /requests/` - Get all requests (Admin/Advisor)
- `POST /requests/{id}/approve` - Approve request (Admin/Advisor)
- `POST /requests/{id}/reject` - Reject request (Admin/Advisor)

### 📅 Attendance
- `POST /attendance/mark` - Mark attendance (Admin/Advisor/Incharge)
- `GET /attendance/me` - Get my attendance (Student)
- `GET /attendance/me/percentage` - Get my attendance percentage (Student)
- `GET /attendance/students/{id}` - Get student attendance (Admin/Advisor/Incharge)
- `GET /attendance/` - Get all attendance records (Admin/Advisor/Incharge)
- `GET /attendance/roster?date=YYYY-MM-DD` - Get roster for date

## 🏗️ Architecture

### Database Schema

**Users Table**
- Core fields: id, username, hashed_password, role
- Profile fields: name, roll_no, semester, year, dob, gender, cgpa, course, section, profile_picture_url
- Indexes: role, roll_no, section+year

**Leave Requests Table**
- Fields: id, student_id, start_date, end_date, reason, status, image_data, assigned_to, approved_by
- Statuses: pending, approved, rejected
- Indexes: student_id+status, status+created_at, date range

**Attendance Records Table**
- Fields: id, student_id, date, status, marked_by
- Statuses: Present, Absent, On-Duty
- Unique index: student_id+date

### Security Features

- **JWT Authentication**: All protected endpoints require valid JWT token
- **Role-Based Access Control**: Enforced at endpoint level
- **Password Hashing**: Bcrypt with timing attack mitigation
- **Rate Limiting**: SlowAPI integration (configurable)
- **CORS**: Configurable allowed origins
- **Input Validation**: Pydantic schemas for all requests
- **SQL Injection Protection**: SQLAlchemy ORM

### Key Workflows

#### Leave Request → Attendance Reflection

1. Student submits leave request with date range
2. Request stored with status="pending"
3. Advisor sees request in pending list
4. Advisor approves request:
   - Request status → "approved"
   - Attendance records created for each date in range
   - Status set to "On-Duty"
5. Changes immediately visible to all roles

## 🧪 Testing

### Automated Workflow Test

```bash
# Ensure backend is running first
python verify_workflow.py
```

This script tests the complete workflow:
- ✅ Student/Advisor login
- ✅ Leave request submission
- ✅ Request visibility to advisor
- ✅ Request approval
- ✅ Automatic attendance record creation
- ✅ Status synchronization

### Manual API Testing

Use the interactive API docs at `/docs` or test with curl:

```bash
# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"23CS001","password":"1234"}'

# Get attendance (replace TOKEN)
curl http://localhost:8000/attendance/me \
  -H "Authorization: Bearer TOKEN"
```

## 🔧 Configuration

### Environment Variables

**Required:**
- `SECRET_KEY` - JWT signing key (must be set)

**Optional:**
- `ALLOWED_ORIGINS` - Comma-separated CORS origins (default: "*")
- `ENVIRONMENT` - "production" or "development" (default: development)
- `TRUSTED_HOSTS` - Comma-separated trusted hosts for production

### Database

- **Type:** SQLite (development) - Easy to switch to PostgreSQL/MySQL
- **File:** `college_attendance.db`
- **Migrations:** Automatic via SQLAlchemy

## 📂 Project Structure

```
backend/
├── main.py                 # FastAPI app & middleware
├── models.py               # SQLAlchemy models
├── schemas.py              # Pydantic schemas
├── database.py             # Database connection
├── auth.py                 # Authentication & authorization
├── logging_config.py       # Logging setup
├── routes/
│   ├── auth.py            # Auth endpoints
│   ├── users.py           # User management
│   ├── attendance_routes/
│   │   ├── marking.py     # Attendance marking
│   │   ├── retrieval.py   # Attendance queries
│   │   └── holidays.py    # Holiday management
│   └── request_routes/
│       └── main.py        # Leave request endpoints
├── static/
│   ├── uploads/           # Profile pictures
│   └── leave_requests/    # Request archives (JSON)
└── logs/
    ├── app.log           # Application logs
    └── error.log         # Error logs
```

## 🐛 Troubleshooting

### Common Issues

**500 Error on Leave Request Submit:**
- Check backend logs: `tail -f logs/error.log`
- Verify image data is Base64 encoded (not raw bytes)

**403 Forbidden:**
- Check JWT token is valid
- Verify user has required role for endpoint

**No data returned:**
- Check database has been seeded: `python reset_and_seed_db.py`
- Verify API endpoint is correct

## 📈 Performance

- **Request timing:** X-Process-Time header on all responses
- **Slow request logging:** >1s requests logged as warnings
- **GZip compression:** Enabled for responses >500 bytes
- **Database indexes:** Optimized for common queries
- **Eager loading:** Relationships loaded efficiently

## 🔒 Production Deployment

1. Set strong `SECRET_KEY`
2. Configure `ALLOWED_ORIGINS` to specific domains
3. Set `ENVIRONMENT=production`
4. Use PostgreSQL instead of SQLite
5. Enable HTTPS/TLS
6. Configure `TRUSTED_HOSTS`
7. Set up proper logging/monitoring
8. Disable `/docs` and `/redoc` endpoints

## 📝 Changelog

### Latest Updates
- ✅ Complete leave request workflow with attendance reflection
- ✅ Role-based access control on all endpoints
- ✅ Profile picture upload
- ✅ Request archiving to JSON files
- ✅ Comprehensive error handling
- ✅ Performance optimizations
- ✅ Automated workflow testing

