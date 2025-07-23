import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/attendance_marking_screen/attendance_marking_screen.dart';
import '../presentation/student_dashboard/student_dashboard.dart';
import '../presentation/advisor_approval_dashboard/advisor_approval_dashboard.dart';
import '../presentation/leave_request_form/leave_request_form.dart';
import '../presentation/student_profile_screen/student_profile_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String loginScreen = '/login-screen';
  static const String attendanceMarkingScreen = '/attendance-marking-screen';
  static const String studentDashboard = '/student-dashboard';
  static const String advisorApprovalDashboard = '/advisor-approval-dashboard';
  static const String leaveRequestForm = '/leave-request-form';
  static const String studentProfileScreen = '/student-profile-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => LoginScreen(),
    loginScreen: (context) => LoginScreen(),
    attendanceMarkingScreen: (context) => AttendanceMarkingScreen(),
    studentDashboard: (context) => StudentDashboard(),
    advisorApprovalDashboard: (context) => AdvisorApprovalDashboard(),
    leaveRequestForm: (context) => LeaveRequestForm(),
    studentProfileScreen: (context) => StudentProfileScreen(),
    // TODO: Add your other routes here
  };
}
