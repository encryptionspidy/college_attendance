#!/usr/bin/env python3
"""
API Load Testing Script
Tests API endpoints under various load conditions to identify bottlenecks.
"""
import requests
import time
import statistics
import concurrent.futures
from typing import List, Dict, Tuple

class LoadTest:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.token = None
        self.results = {}
    
    def login(self, username="admin", password="admin123"):
        """Login and get auth token."""
        print("\n🔐 Logging in...")
        response = requests.post(
            f"{self.base_url}/token",
            data={"username": username, "password": password},
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        if response.status_code == 200:
            self.token = response.json()["access_token"]
            print(f"  ✅ Logged in successfully")
            return True
        else:
            print(f"  ❌ Login failed: {response.status_code}")
            return False
    
    def test_endpoint(self, endpoint: str, method="GET", data=None, runs=10) -> Tuple[float, float, List[float]]:
        """Test a single endpoint multiple times."""
        headers = {"Authorization": f"Bearer {self.token}"}
        times = []
        errors = 0
        
        for _ in range(runs):
            start = time.time()
            try:
                if method == "GET":
                    response = requests.get(f"{self.base_url}{endpoint}", headers=headers, timeout=10)
                elif method == "POST":
                    response = requests.post(f"{self.base_url}{endpoint}", headers=headers, json=data, timeout=10)
                
                elapsed = (time.time() - start) * 1000  # Convert to ms
                times.append(elapsed)
                
                if response.status_code >= 400:
                    errors += 1
            except Exception as e:
                errors += 1
                times.append(10000)  # 10s timeout
        
        avg_time = statistics.mean(times)
        p95_time = sorted(times)[int(len(times) * 0.95)]
        
        return avg_time, p95_time, times, errors
    
    def concurrent_test(self, endpoint: str, concurrent_requests=10, total_requests=100):
        """Test endpoint with concurrent requests."""
        print(f"\n⚡ Concurrent test: {endpoint}")
        print(f"   Concurrent: {concurrent_requests}, Total: {total_requests}")
        
        def make_request():
            headers = {"Authorization": f"Bearer {self.token}"}
            start = time.time()
            try:
                response = requests.get(f"{self.base_url}{endpoint}", headers=headers, timeout=10)
                elapsed = (time.time() - start) * 1000
                return elapsed, response.status_code
            except:
                return 10000, 500
        
        start_time = time.time()
        with concurrent.futures.ThreadPoolExecutor(max_workers=concurrent_requests) as executor:
            futures = [executor.submit(make_request) for _ in range(total_requests)]
            results = [f.result() for f in concurrent.futures.as_completed(futures)]
        
        total_time = time.time() - start_time
        times = [r[0] for r in results]
        errors = sum(1 for r in results if r[1] >= 400)
        
        avg_time = statistics.mean(times)
        p95_time = sorted(times)[int(len(times) * 0.95)]
        throughput = total_requests / total_time
        
        print(f"   Total time: {total_time:.2f}s")
        print(f"   Throughput: {throughput:.2f} req/s")
        print(f"   Avg response: {avg_time:.2f}ms")
        print(f"   P95 response: {p95_time:.2f}ms")
        print(f"   Errors: {errors}/{total_requests}")
        
        status = "✅ EXCELLENT" if avg_time < 100 and errors == 0 else "⚠️ NEEDS ATTENTION" if errors > 0 else "✅ GOOD"
        print(f"   Status: {status}")
        
        return {
            'avg_time': avg_time,
            'p95_time': p95_time,
            'throughput': throughput,
            'errors': errors,
            'total_requests': total_requests
        }
    
    def run_endpoint_tests(self):
        """Test individual endpoints."""
        print("\n" + "="*70)
        print("🧪 ENDPOINT RESPONSE TIME TESTS")
        print("="*70)
        
        endpoints = [
            ("/users/me", "GET"),
            ("/users/students", "GET"),
            ("/attendance/", "GET"),
            ("/requests/", "GET"),
        ]
        
        results = []
        for endpoint, method in endpoints:
            print(f"\n{method} {endpoint}")
            avg, p95, times, errors = self.test_endpoint(endpoint, method)
            
            status = "✅" if avg < 100 else "⚠️" if avg < 500 else "❌"
            print(f"  Avg: {avg:.2f}ms | P95: {p95:.2f}ms | Errors: {errors}/10 {status}")
            
            results.append({
                'endpoint': endpoint,
                'avg': avg,
                'p95': p95,
                'errors': errors
            })
        
        return results
    
    def run_load_tests(self):
        """Run load tests with concurrent requests."""
        print("\n" + "="*70)
        print("🚀 LOAD TESTING (Concurrent Requests)")
        print("="*70)
        
        tests = [
            ("/users/me", 5, 50),
            ("/users/students", 10, 100),
            ("/attendance/", 10, 100),
        ]
        
        results = []
        for endpoint, concurrent, total in tests:
            result = self.concurrent_test(endpoint, concurrent, total)
            results.append({'endpoint': endpoint, **result})
        
        return results
    
    def generate_report(self):
        """Generate comprehensive load test report."""
        print("\n" + "="*70)
        print("📊 LOAD TEST SUMMARY")
        print("="*70)
        
        print("\n✅ Performance Benchmarks:")
        print("  Excellent: <100ms average response time")
        print("  Good: <500ms average response time")
        print("  Needs attention: >500ms or any errors")
        
        print("\n💡 Recommendations:")
        print("  1. Monitor slow endpoints and optimize queries")
        print("  2. Add caching for frequently accessed data")
        print("  3. Use pagination for large result sets")
        print("  4. Consider connection pooling for high concurrency")
        print("  5. Monitor database query performance")
        
        print("\n" + "="*70)
    
    def run_all_tests(self):
        """Run all load tests."""
        print("\n" + "="*70)
        print("🧪 COMPREHENSIVE API LOAD TESTING")
        print("="*70)
        
        if not self.login():
            print("\n❌ Cannot proceed without authentication")
            return 1
        
        try:
            self.run_endpoint_tests()
            self.run_load_tests()
            self.generate_report()
            
            print("\n✅ Load testing completed!")
            return 0
        except Exception as e:
            print(f"\n❌ Error during load testing: {e}")
            import traceback
            traceback.print_exc()
            return 1

if __name__ == "__main__":
    import sys
    
    # Check if server is running
    print("🔍 Checking if server is running...")
    try:
        response = requests.get("http://localhost:8000/", timeout=5)
        print("✅ Server is running\n")
    except:
        print("❌ Server is not running. Please start the server first:")
        print("   cd backend && python3 run_server.py")
        sys.exit(1)
    
    tester = LoadTest()
    sys.exit(tester.run_all_tests())
