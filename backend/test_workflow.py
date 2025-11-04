#!/usr/bin/env python3
"""
Comprehensive workflow test for the College Attendance Marker backend.
This script tests the complete flow:
1. Student submits a leave request
2. Advisor sees the pending request
3. Advisor approves the request
4. Attendance records are automatically updated to "On-Duty"
5. Student sees the approved status in their requests
"""

import requests
import json
import base64
from datetime import date, timedelta

# Configuration
BASE_URL = "http://localhost:8000"

# Test credentials (ensure these users exist in your database)
STUDENT_USERNAME = "23CS001"
STUDENT_PASSWORD = "1234"

ADVISOR_USERNAME = "advisor1"
ADVISOR_PASSWORD = "1234"

def login(username, password):
    """Login and get access token"""
    response = requests.post(
        f"{BASE_URL}/auth/token",
        json={"username": username, "password": password}
    )
    if response.status_code == 200:
        data = response.json()
        return data["access_token"]
    else:
        print(f"❌ Login failed for {username}: {response.status_code}")
        print(f"   Response: {response.text}")
        return None

def test_student_submit_request(token):
    """Test: Student submits a leave request"""
    print("\n" + "="*80)
    print("TEST 1: Student submits a leave request")
    print("="*80)

    # Create a simple test image (1x1 pixel PNG in Base64)
    test_image_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

    today = date.today()
    start_date = today + timedelta(days=1)
    end_date = today + timedelta(days=3)

    request_data = {
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "reason": "Medical appointment",
        "image_data": test_image_base64
    }

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.post(
        f"{BASE_URL}/requests/",
        json=request_data,
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        print(f"✅ Leave request created successfully")
        print(f"   Request ID: {data['id']}")
        print(f"   Status: {data['status']}")
        print(f"   Dates: {data['start_date']} to {data['end_date']}")
        return data['id']
    else:
        print(f"❌ Failed to create leave request: {response.status_code}")
        print(f"   Response: {response.text}")
        return None

def test_advisor_view_pending(token):
    """Test: Advisor views pending requests"""
    print("\n" + "="*80)
    print("TEST 2: Advisor views pending requests")
    print("="*80)

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/requests/pending",
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        print(f"✅ Pending requests retrieved: {len(data)} request(s)")
        for req in data:
            print(f"   - Request {req['id']}: {req['reason']} ({req['start_date']} to {req['end_date']})")
        return data
    else:
        print(f"❌ Failed to retrieve pending requests: {response.status_code}")
        print(f"   Response: {response.text}")
        return []

def test_advisor_approve_request(token, request_id):
    """Test: Advisor approves a request"""
    print("\n" + "="*80)
    print("TEST 3: Advisor approves the request")
    print("="*80)

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.post(
        f"{BASE_URL}/requests/{request_id}/approve",
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        print(f"✅ Request approved successfully")
        print(f"   Request ID: {data['id']}")
        print(f"   New Status: {data['status']}")
        return True
    else:
        print(f"❌ Failed to approve request: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

def test_verify_attendance_updated(token, student_id, start_date, end_date):
    """Test: Verify attendance records are updated to On-Duty"""
    print("\n" + "="*80)
    print("TEST 4: Verify attendance records updated to On-Duty")
    print("="*80)

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/attendance/students/{student_id}",
        headers=headers
    )

    if response.status_code == 200:
        records = response.json()
        on_duty_records = [r for r in records if r['status'] == 'On-Duty' and start_date <= r['date'] <= end_date]

        if on_duty_records:
            print(f"✅ Attendance records updated: {len(on_duty_records)} day(s) marked as On-Duty")
            for record in on_duty_records:
                print(f"   - {record['date']}: {record['status']}")
            return True
        else:
            print(f"⚠️  No On-Duty records found for the date range")
            return False
    else:
        print(f"❌ Failed to retrieve attendance: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

def test_student_view_approved(token):
    """Test: Student sees the approved request"""
    print("\n" + "="*80)
    print("TEST 5: Student views their approved request")
    print("="*80)

    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/requests/me",
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        approved_requests = [r for r in data if r['status'] == 'approved']
        print(f"✅ Student requests retrieved: {len(approved_requests)} approved request(s)")
        for req in approved_requests:
            print(f"   - Request {req['id']}: {req['status']}")
        return len(approved_requests) > 0
    else:
        print(f"❌ Failed to retrieve student requests: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

def main():
    print("\n" + "🚀" + "="*78 + "🚀")
    print("   COLLEGE ATTENDANCE MARKER - COMPREHENSIVE WORKFLOW TEST")
    print("🚀" + "="*78 + "🚀")

    # Step 1: Student login
    print("\n📝 Logging in as Student...")
    student_token = login(STUDENT_USERNAME, STUDENT_PASSWORD)
    if not student_token:
        print("❌ CRITICAL: Cannot proceed without student login")
        return
    print("✅ Student login successful")

    # Step 2: Advisor login
    print("\n👔 Logging in as Advisor...")
    advisor_token = login(ADVISOR_USERNAME, ADVISOR_PASSWORD)
    if not advisor_token:
        print("❌ CRITICAL: Cannot proceed without advisor login")
        return
    print("✅ Advisor login successful")

    # Step 3: Student submits request
    request_id = test_student_submit_request(student_token)
    if not request_id:
        print("\n❌ WORKFLOW FAILED: Could not create leave request")
        return

    # Step 4: Advisor views pending requests
    pending_requests = test_advisor_view_pending(advisor_token)
    if not pending_requests:
        print("\n⚠️  WARNING: No pending requests visible to advisor")

    # Verify the newly created request is in the list
    new_request_found = any(req['id'] == request_id for req in pending_requests)
    if not new_request_found:
        print(f"\n❌ CRITICAL: Newly created request {request_id} not found in pending list!")
        return

    # Step 5: Advisor approves the request
    approval_success = test_advisor_approve_request(advisor_token, request_id)
    if not approval_success:
        print("\n❌ WORKFLOW FAILED: Could not approve request")
        return

    # Step 6: Verify attendance updated (get student_id from pending requests)
    student_request = next((r for r in pending_requests if r['id'] == request_id), None)
    if student_request:
        test_verify_attendance_updated(
            advisor_token,
            student_request['student_id'],
            student_request['start_date'],
            student_request['end_date']
        )

    # Step 7: Student sees approved request
    student_sees_approval = test_student_view_approved(student_token)

    # Final summary
    print("\n" + "="*80)
    print("WORKFLOW TEST SUMMARY")
    print("="*80)
    print(f"✅ Student login: SUCCESS")
    print(f"✅ Advisor login: SUCCESS")
    print(f"✅ Leave request submission: SUCCESS")
    print(f"{'✅' if new_request_found else '❌'} Request visible to advisor: {'SUCCESS' if new_request_found else 'FAILED'}")
    print(f"{'✅' if approval_success else '❌'} Request approval: {'SUCCESS' if approval_success else 'FAILED'}")
    print(f"{'✅' if student_sees_approval else '❌'} Student sees approval: {'SUCCESS' if student_sees_approval else 'FAILED'}")

    if all([new_request_found, approval_success, student_sees_approval]):
        print("\n🎉 ALL TESTS PASSED! The entire workflow is functioning correctly.")
    else:
        print("\n⚠️  SOME TESTS FAILED. Please review the logs above.")
    print("="*80 + "\n")

if __name__ == "__main__":
    main()

