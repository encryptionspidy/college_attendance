#!/usr/bin/env python3
"""
Comprehensive Backend Workflow Verification Script
Tests the complete leave request → approval → attendance reflection pipeline
"""

import requests
import json
from datetime import datetime, timedelta
import sys

# Configuration
BASE_URL = "http://localhost:8000"
STUDENT_USERNAME = "23CS001"
STUDENT_PASSWORD = "1234"
ADVISOR_USERNAME = "advisor1"
ADVISOR_PASSWORD = "1234"

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def login(username, password):
    """Login and get access token"""
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"username": username, "password": password}
    )
    if response.status_code == 200:
        data = response.json()
        return data["access_token"]
    else:
        print(f"❌ Login failed for {username}: {response.status_code}")
        print(response.text)
        return None

def test_leave_request_workflow():
    """Test complete workflow from request submission to approval"""

    print_section("🧪 BACKEND WORKFLOW VERIFICATION TEST")

    # Step 1: Student Login
    print_section("Step 1: Student Login")
    student_token = login(STUDENT_USERNAME, STUDENT_PASSWORD)
    if not student_token:
        print("❌ FAILED: Could not login as student")
        return False
    print(f"✅ Student logged in successfully")

    # Step 2: Advisor Login
    print_section("Step 2: Advisor Login")
    advisor_token = login(ADVISOR_USERNAME, ADVISOR_PASSWORD)
    if not advisor_token:
        print("❌ FAILED: Could not login as advisor")
        return False
    print(f"✅ Advisor logged in successfully")

    # Step 3: Student submits leave request
    print_section("Step 3: Submit Leave Request")
    start_date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    end_date = (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%d")

    request_data = {
        "start_date": start_date,
        "end_date": end_date,
        "reason": "Backend workflow verification test",
        "image_data": None
    }

    response = requests.post(
        f"{BASE_URL}/requests/",
        json=request_data,
        headers={"Authorization": f"Bearer {student_token}"}
    )

    if response.status_code != 200:
        print(f"❌ FAILED: Could not create request: {response.status_code}")
        print(response.text)
        return False

    request_id = response.json()["id"]
    print(f"✅ Leave request created: ID={request_id}")
    print(f"   Date range: {start_date} to {end_date}")

    # Step 4: Verify request appears in advisor's pending list
    print_section("Step 4: Verify Advisor Can See Request")
    response = requests.get(
        f"{BASE_URL}/requests/pending",
        headers={"Authorization": f"Bearer {advisor_token}"}
    )

    if response.status_code != 200:
        print(f"❌ FAILED: Could not fetch pending requests: {response.status_code}")
        print(response.text)
        return False

    pending_requests = response.json()
    found = False
    for req in pending_requests:
        if req["id"] == request_id:
            found = True
            break

    if not found:
        print(f"❌ FAILED: Request {request_id} not found in advisor's pending list")
        return False

    print(f"✅ Request visible to advisor (found in {len(pending_requests)} pending requests)")

    # Step 5: Advisor approves the request
    print_section("Step 5: Approve Request")
    response = requests.post(
        f"{BASE_URL}/requests/{request_id}/approve",
        headers={"Authorization": f"Bearer {advisor_token}"}
    )

    if response.status_code != 200:
        print(f"❌ FAILED: Could not approve request: {response.status_code}")
        print(response.text)
        return False

    approved_request = response.json()
    if approved_request["status"] != "approved":
        print(f"❌ FAILED: Request status is {approved_request['status']}, expected 'approved'")
        return False

    print(f"✅ Request approved successfully")

    # Step 6: Verify attendance records created
    print_section("Step 6: Verify Attendance Records Created")
    response = requests.get(
        f"{BASE_URL}/attendance/me",
        headers={"Authorization": f"Bearer {student_token}"}
    )

    if response.status_code != 200:
        print(f"❌ FAILED: Could not fetch attendance: {response.status_code}")
        print(response.text)
        return False

    attendance_records = response.json()

    # Check if On-Duty records exist for the date range
    start = datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.strptime(end_date, "%Y-%m-%d").date()
    expected_dates = []
    current = start
    while current <= end:
        expected_dates.append(current.strftime("%Y-%m-%d"))
        current += timedelta(days=1)

    found_dates = []
    for record in attendance_records:
        if record["status"] == "On-Duty" and record["date"] in expected_dates:
            found_dates.append(record["date"])

    if len(found_dates) != len(expected_dates):
        print(f"❌ FAILED: Expected {len(expected_dates)} On-Duty records, found {len(found_dates)}")
        print(f"   Expected: {expected_dates}")
        print(f"   Found: {found_dates}")
        return False

    print(f"✅ All {len(expected_dates)} attendance records created correctly")
    print(f"   Dates: {', '.join(expected_dates)}")

    # Step 7: Verify request no longer in pending list
    print_section("Step 7: Verify Request Removed from Pending")
    response = requests.get(
        f"{BASE_URL}/requests/pending",
        headers={"Authorization": f"Bearer {advisor_token}"}
    )

    if response.status_code != 200:
        print(f"❌ FAILED: Could not fetch pending requests: {response.status_code}")
        return False

    pending_requests = response.json()
    for req in pending_requests:
        if req["id"] == request_id:
            print(f"❌ FAILED: Approved request still in pending list")
            return False

    print(f"✅ Approved request correctly removed from pending list")

    # Final Summary
    print_section("🎉 WORKFLOW VERIFICATION COMPLETE")
    print("✅ Student can submit leave request")
    print("✅ Advisor can see pending request")
    print("✅ Advisor can approve request")
    print("✅ Attendance records automatically created as 'On-Duty'")
    print("✅ Approved request removed from pending list")
    print("\n✅ ALL TESTS PASSED - Backend workflow is working correctly!\n")

    return True

if __name__ == "__main__":
    try:
        success = test_leave_request_workflow()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ UNEXPECTED ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

