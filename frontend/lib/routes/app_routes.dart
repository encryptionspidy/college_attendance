import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/attendance_incharge_dashboard/attendance_incharge_dashboard.dart';
import '../presentation/student_dashboard/student_dashboard.dart';
import '../presentation/advisor_dashboard/advisor_dashboard.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/leave_request_form/leave_request_form.dart';
import '../presentation/on_duty_request_form/on_duty_request_form.dart';
import '../presentation/request_history_screen/request_history_screen.dart';
import '../presentation/student_profile_screen/student_profile_screen.dart';
import '../presentation/edit_profile_screen/edit_profile_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String loginScreen = '/login-screen';
  static const String attendanceMarkingScreen = '/attendance-marking-screen';
  static const String studentDashboard = '/student-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String advisorApprovalDashboard = '/advisor-approval-dashboard';
  static const String leaveRequestForm = '/leave-request-form';
  static const String onDutyRequestForm = '/on-duty-request-form';
  static const String requestHistoryScreen = '/request-history-screen';
  static const String studentProfileScreen = '/student-profile-screen';
  static const String editProfileScreen = '/edit-profile-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => LoginScreen(),
    loginScreen: (context) => LoginScreen(),
    attendanceMarkingScreen: (context) => AttendanceInchargeDashboard(),
    studentDashboard: (context) => StudentDashboard(),
    adminDashboard: (context) => AdminDashboard(),
    advisorApprovalDashboard: (context) => AdvisorDashboard(),
    leaveRequestForm: (context) => LeaveRequestForm(),
    onDutyRequestForm: (context) => OnDutyRequestForm(),
    requestHistoryScreen: (context) => RequestHistoryScreen(),
    studentProfileScreen: (context) => StudentProfileScreen(),
    editProfileScreen: (context) => EditProfileScreen(),
  };
}
