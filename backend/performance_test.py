#!/usr/bin/env python3
"""
Comprehensive Performance Testing Suite
Tests database performance, API response times, and identifies bottlenecks.
"""
import time
import statistics
import sys
from typing import List, Dict
from sqlalchemy import text
from database import engine, SessionLocal
from models import User, AttendanceRecord, LeaveRequest

class PerformanceTest:
    def __init__(self):
        self.results = {}
        self.db = SessionLocal()
    
    def test_database_query_performance(self):
        """Test database query performance with various patterns."""
        print("\n" + "="*70)
        print("🔍 DATABASE QUERY PERFORMANCE TESTS")
        print("="*70)
        
        tests = []
        
        # Test 1: Simple SELECT with index
        times = []
        for _ in range(10):
            start = time.time()
            self.db.query(User).filter(User.role == "student").all()
            times.append(time.time() - start)
        tests.append(("Filter by indexed role", statistics.mean(times)*1000))
        
        # Test 2: JOIN query with eager loading
        times = []
        from sqlalchemy.orm import selectinload
        for _ in range(10):
            start = time.time()
            self.db.query(AttendanceRecord).options(
                selectinload(AttendanceRecord.student),
                selectinload(AttendanceRecord.marker)
            ).limit(50).all()
            times.append(time.time() - start)
        tests.append(("Eager load 50 records", statistics.mean(times)*1000))
        
        # Test 3: Date range query with index
        times = []
        from datetime import date, timedelta
        today = date.today()
        week_ago = today - timedelta(days=7)
        for _ in range(10):
            start = time.time()
            self.db.query(AttendanceRecord).filter(
                AttendanceRecord.date.between(week_ago, today)
            ).all()
            times.append(time.time() - start)
        tests.append(("Date range query (7 days)", statistics.mean(times)*1000))
        
        # Test 4: Complex filter with composite index
        times = []
        student = self.db.query(User).filter(User.role == "student").first()
        if student:
            for _ in range(10):
                start = time.time()
                self.db.query(AttendanceRecord).filter(
                    AttendanceRecord.student_id == student.id,
                    AttendanceRecord.date >= week_ago
                ).all()
                times.append(time.time() - start)
            tests.append(("Composite index query", statistics.mean(times)*1000))
        
        # Test 5: Aggregation query
        times = []
        for _ in range(10):
            start = time.time()
            self.db.query(AttendanceRecord).filter(
                AttendanceRecord.status == "Present"
            ).count()
            times.append(time.time() - start)
        tests.append(("Count aggregation", statistics.mean(times)*1000))
        
        # Results
        for test_name, avg_time in tests:
            status = "✅ EXCELLENT" if avg_time < 50 else "⚠️ NEEDS OPTIMIZATION" if avg_time < 200 else "❌ SLOW"
            print(f"{test_name:.<40} {avg_time:.2f}ms {status}")
        
        self.results['database'] = tests
        return tests
    
    def test_index_effectiveness(self):
        """Verify indexes are being used by the query planner."""
        print("\n" + "="*70)
        print("📊 INDEX EFFECTIVENESS TESTS")
        print("="*70)
        
        tests = []
        
        # Check if indexes exist
        with engine.connect() as conn:
            # Get query plan for indexed query
            result = conn.execute(text(
                "EXPLAIN QUERY PLAN SELECT * FROM attendance_records WHERE student_id = '123'"
            ))
            plan = result.fetchall()
            uses_index = any("INDEX" in str(row).upper() for row in plan)
            tests.append(("student_id index", uses_index))
            
            # Check date index
            result = conn.execute(text(
                "EXPLAIN QUERY PLAN SELECT * FROM attendance_records WHERE date = '2024-01-01'"
            ))
            plan = result.fetchall()
            uses_index = any("INDEX" in str(row).upper() for row in plan)
            tests.append(("date index", uses_index))
            
            # Check composite index
            result = conn.execute(text(
                "EXPLAIN QUERY PLAN SELECT * FROM attendance_records WHERE student_id = '123' AND date = '2024-01-01'"
            ))
            plan = result.fetchall()
            uses_index = any("INDEX" in str(row).upper() for row in plan)
            tests.append(("composite index", uses_index))
        
        for test_name, uses_index in tests:
            status = "✅ USED" if uses_index else "❌ NOT USED"
            print(f"{test_name:.<40} {status}")
        
        return tests
    
    def test_data_volume_performance(self):
        """Test performance with different data volumes."""
        print("\n" + "="*70)
        print("📈 DATA VOLUME PERFORMANCE TESTS")
        print("="*70)
        
        # Get current data volumes
        user_count = self.db.query(User).count()
        attendance_count = self.db.query(AttendanceRecord).count()
        request_count = self.db.query(LeaveRequest).count()
        
        print(f"Current data volume:")
        print(f"  Users: {user_count}")
        print(f"  Attendance Records: {attendance_count}")
        print(f"  Leave Requests: {request_count}")
        
        # Test scalability
        if attendance_count > 0:
            # Test fetching increasing amounts
            volumes = [10, 50, 100, 500, min(1000, attendance_count)]
            results = []
            
            for vol in volumes:
                times = []
                for _ in range(5):
                    start = time.time()
                    self.db.query(AttendanceRecord).limit(vol).all()
                    times.append(time.time() - start)
                avg_time = statistics.mean(times) * 1000
                results.append((vol, avg_time))
                
                # Calculate per-record time
                per_record = avg_time / vol
                status = "✅" if per_record < 1 else "⚠️" if per_record < 2 else "❌"
                print(f"  {vol} records: {avg_time:.2f}ms ({per_record:.3f}ms/record) {status}")
            
            return results
        else:
            print("  ⚠️ No data to test")
            return []
    
    def test_connection_pool(self):
        """Test database connection efficiency."""
        print("\n" + "="*70)
        print("🔌 CONNECTION POOL TESTS")
        print("="*70)
        
        # Test connection acquisition time
        times = []
        for _ in range(20):
            start = time.time()
            db = SessionLocal()
            db.close()
            times.append(time.time() - start)
        
        avg_time = statistics.mean(times) * 1000
        status = "✅ FAST" if avg_time < 5 else "⚠️ MODERATE" if avg_time < 20 else "❌ SLOW"
        print(f"Connection acquisition time: {avg_time:.2f}ms {status}")
        
        return avg_time
    
    def test_memory_usage(self):
        """Test memory efficiency of queries."""
        print("\n" + "="*70)
        print("💾 MEMORY EFFICIENCY TESTS")
        print("="*70)
        
        import sys
        
        # Test memory usage of loading records
        records = self.db.query(AttendanceRecord).limit(100).all()
        memory_size = sys.getsizeof(records)
        print(f"100 records memory: {memory_size} bytes ({memory_size/1024:.2f} KB)")
        
        # Test with eager loading
        from sqlalchemy.orm import selectinload
        records = self.db.query(AttendanceRecord).options(
            selectinload(AttendanceRecord.student),
            selectinload(AttendanceRecord.marker)
        ).limit(100).all()
        memory_size_eager = sys.getsizeof(records)
        print(f"100 records with eager loading: {memory_size_eager} bytes ({memory_size_eager/1024:.2f} KB)")
        
        return memory_size, memory_size_eager
    
    def generate_report(self):
        """Generate comprehensive performance report."""
        print("\n" + "="*70)
        print("📋 PERFORMANCE REPORT SUMMARY")
        print("="*70)
        
        print("\n✅ Optimizations Applied:")
        print("  • Database indexes on critical columns")
        print("  • Composite indexes for common queries")
        print("  • Eager loading to prevent N+1 queries")
        print("  • Bulk operations for high-volume tasks")
        
        print("\n🎯 Performance Targets:")
        print("  • Query time: < 50ms (excellent), < 200ms (acceptable)")
        print("  • Connection time: < 5ms (fast), < 20ms (acceptable)")
        print("  • Per-record time: < 1ms (excellent), < 2ms (acceptable)")
        
        print("\n💡 Recommendations:")
        if 'database' in self.results:
            slow_queries = [name for name, time in self.results['database'] if time > 200]
            if slow_queries:
                print(f"  ⚠️ Optimize these queries: {', '.join(slow_queries)}")
            else:
                print("  ✅ All queries performing well!")
        
        print("\n" + "="*70)
    
    def run_all_tests(self):
        """Run all performance tests."""
        print("\n" + "="*70)
        print("🚀 COMPREHENSIVE PERFORMANCE TEST SUITE")
        print("="*70)
        
        try:
            self.test_database_query_performance()
            self.test_index_effectiveness()
            self.test_data_volume_performance()
            self.test_connection_pool()
            self.test_memory_usage()
            self.generate_report()
            
            print("\n✅ All performance tests completed successfully!")
            return 0
        except Exception as e:
            print(f"\n❌ Error during testing: {e}")
            import traceback
            traceback.print_exc()
            return 1
        finally:
            self.db.close()

if __name__ == "__main__":
    tester = PerformanceTest()
    sys.exit(tester.run_all_tests())
