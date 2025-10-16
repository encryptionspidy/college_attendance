#!/usr/bin/env python3
"""
Verification script to confirm all performance optimizations are in place.
"""
import sys
import os

def check_database_indexes():
    """Verify all critical indexes exist."""
    try:
        from database import engine
        from sqlalchemy import inspect
        
        inspector = inspect(engine)
        
        # Expected indexes
        expected = {
            'users': ['ix_users_role', 'ix_users_username', 'ix_users_id'],
            'attendance_records': [
                'ix_attendance_records_student_id',
                'ix_attendance_records_date',
                'ix_attendance_records_student_date',
                'ix_attendance_records_id'
            ],
            'leave_requests': [
                'ix_leave_requests_student_id',
                'ix_leave_requests_status',
                'ix_leave_requests_student_status',
                'ix_leave_requests_id'
            ]
        }
        
        all_good = True
        print("\n📊 Checking Database Indexes...")
        print("=" * 60)
        
        for table_name, expected_indexes in expected.items():
            actual_indexes = [idx['name'] for idx in inspector.get_indexes(table_name)]
            print(f"\n{table_name}:")
            
            for idx_name in expected_indexes:
                if idx_name in actual_indexes:
                    print(f"  ✅ {idx_name}")
                else:
                    print(f"  ❌ {idx_name} - MISSING!")
                    all_good = False
        
        return all_good
    except Exception as e:
        print(f"❌ Error checking indexes: {e}")
        return False

def check_code_imports():
    """Verify optimized code imports correctly."""
    print("\n🔍 Checking Code Imports...")
    print("=" * 60)
    
    try:
        # Check models with indexes
        from models import User, AttendanceRecord, LeaveRequest
        print("  ✅ Models with indexes import correctly")
        
        # Check updated routes
        from routes.attendance_routes import retrieval, marking
        print("  ✅ Optimized attendance routes import correctly")
        
        from routes.request_routes import main as request_routes
        print("  ✅ Optimized request routes import correctly")
        
        from routes import users
        print("  ✅ Optimized user routes import correctly")
        
        # Check main app
        import main
        print("  ✅ Main app with GZip middleware imports correctly")
        
        return True
    except Exception as e:
        print(f"  ❌ Import error: {e}")
        return False

def check_file_modifications():
    """Verify key files have been modified."""
    print("\n📝 Checking File Modifications...")
    print("=" * 60)
    
    checks = [
        ('models.py', ['Index', '__table_args__']),
        ('main.py', ['GZipMiddleware']),
        ('routes/attendance_routes/retrieval.py', ['selectinload']),
        ('routes/attendance_routes/marking.py', ['in_']),
        ('routes/request_routes/main.py', ['selectinload']),
        ('add_indexes.py', ['CREATE INDEX']),
    ]
    
    all_good = True
    for filename, keywords in checks:
        try:
            with open(filename, 'r') as f:
                content = f.read()
                has_all = all(kw in content for kw in keywords)
                if has_all:
                    print(f"  ✅ {filename} - optimized")
                else:
                    print(f"  ⚠️  {filename} - may need review")
                    all_good = False
        except FileNotFoundError:
            print(f"  ❌ {filename} - not found")
            all_good = False
    
    return all_good

def main():
    """Run all verification checks."""
    print("\n" + "=" * 60)
    print("🚀 Performance Optimization Verification")
    print("=" * 60)
    
    # Change to backend directory if not already there
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    results = []
    
    # Run checks
    results.append(("Database Indexes", check_database_indexes()))
    results.append(("Code Imports", check_code_imports()))
    results.append(("File Modifications", check_file_modifications()))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 Verification Summary")
    print("=" * 60)
    
    all_passed = True
    for check_name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{check_name}: {status}")
        if not passed:
            all_passed = False
    
    print("=" * 60)
    
    if all_passed:
        print("\n🎉 All optimizations verified successfully!")
        print("📈 Application is production-ready with optimized performance.")
        return 0
    else:
        print("\n⚠️  Some checks failed. Review the output above.")
        print("💡 Tip: Run 'python3 add_indexes.py' if indexes are missing.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
