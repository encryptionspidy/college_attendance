# College Attendance Marker

A comprehensive Flutter mobile application for managing college attendance with role-based access control.

## Features

### 🎯 Multi-Role System
- **Students**: Submit leave requests, view attendance history
- **Attendance Incharge**: Mark daily attendance, manage special days  
- **Advisors**: Approve leave requests, view attendance reports
- **Admins**: Full system access, user management, comprehensive reports

### 📱 Core Functionality
- **Attendance Marking**: Easy daily attendance tracking with bulk operations
- **Leave Management**: Digital leave request submission and approval workflow
- **Special Days**: Mark holidays, weekends, and custom events
- **Offline Support**: Works without internet, syncs when connected
- **Digital Signatures**: Advisor approval with signature validation

## Project Structure

```
college_attendance_marker/
├── backend/                 # FastAPI Python backend
│   ├── routes/             # API route handlers
│   ├── models.py           # Database models
│   ├── auth.py             # Authentication logic
│   └── main.py             # FastAPI application entry point
├── frontend/               # Flutter mobile application
│   ├── lib/
│   │   ├── src/
│   │   │   ├── features/   # Feature-based modules
│   │   │   ├── core/       # Core services and utilities
│   │   │   ├── models/     # Data models
│   │   │   └── providers/  # State management
│   │   └── main.dart       # Flutter app entry point
│   └── android/            # Android build configuration
└── README.md              # This file
```

## Setup Instructions

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Initialize database:**
   ```bash
   python init_db.py
   ```

4. **Start the server:**
   ```bash
   python run_server.py
   ```

### Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API configuration:**
   - Edit `env.json` to set correct backend URL
   
4. **Run the application:**
   ```bash
   flutter run
   ```

## API Configuration

The app connects to the backend via the URL specified in `frontend/env.json`:

```json
{
  "API_BASE_URL": "http://your-backend-ip:8000"
}
```

## Default Users

The system comes with pre-configured test users:

- **Admin**: `admin` / `admin123`
- **Advisor**: `advisor1` / `advisor123` 
- **Attendance Incharge**: `attendance_incharge` / `attendance123`
- **Student**: `student1` / `student123`

## Technologies Used

### Backend
- **FastAPI**: Modern Python web framework
- **SQLAlchemy**: Database ORM
- **JWT**: Authentication tokens
- **SQLite**: Local database storage

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **Hive**: Local data storage
- **Dio**: HTTP client for API calls

## Recent Bug Fixes

✅ **Fixed logout navigation** - Resolved hardcoded route issues  
✅ **Improved read-only mode** - Attendance now editable by default  
✅ **Debug connection helper** - Added script for ADB connection issues  
✅ **Data loading optimization** - Fixed advisor panel initial load  
✅ **Type casting fixes** - Resolved UUID/int conversion errors

## Development Notes

- The app supports offline functionality with automatic sync
- Role-based access control ensures data security
- Digital signature support for leave approvals
- Comprehensive error handling and user feedback

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly across all user roles
5. Submit a pull request

## License

This project is developed for educational purposes.
