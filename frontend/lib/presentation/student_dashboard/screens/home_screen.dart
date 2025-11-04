import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_service.dart';
import '../../../core/app_export.dart';
import '../../leave_request_form/leave_request_form.dart';
import '../../on_duty_request_form/on_duty_request_form.dart';
import '../../request_history_screen/request_history_screen.dart';
import '../widgets/glass_card.dart';

/// Tab 1: Home Screen - The Overview
///
/// Clean, at-a-glance summary with:
/// - Real-time attendance percentage in a well-proportioned GlassCard
/// - Quick action buttons for common tasks
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _studentName = 'Student';
  String _rollNo = '';
  double _attendancePercentage = 0.0;
  int _presentDays = 0;
  int _totalDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getStudentHomeData();
      final user = data['user'];
      final stats = data['stats'];
      if (mounted) {
        setState(() {
          _studentName = user?['name'] ?? user?['username'] ?? 'Student';
          _rollNo = user?['roll_no'] ?? '';
          _attendancePercentage = (stats['percentage'] ?? 0.0);
          _presentDays = stats['present_days'] ?? 0;
          _totalDays = stats['total_days'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF0A0E21);
    const accentColor = Color(0xFF00D9FF);
    const accentSecondary = Color(0xFF8B5CF6);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: accentColor,
      backgroundColor: const Color(0xFF1D1E33),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Welcome Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _studentName,
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_rollNo.isNotEmpty)
                    Text(
                      'Roll No: $_rollNo',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: accentColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Attendance Overview Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: _isLoading
                  ? GlassCard(
                      child: SizedBox(
                        height: 25.h,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    )
                  : GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'Your Attendance',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          GlassProgressIndicator(
                            percentage: _attendancePercentage,
                            accentColor: _attendancePercentage >= 75
                                ? const Color(0xFF4CAF50)
                                : _attendancePercentage >= 50
                                    ? const Color(0xFFFFA726)
                                    : const Color(0xFFEF5350),
                            size: 100,
                          ),
                          SizedBox(height: 3.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Present',
                                _presentDays.toString(),
                                const Color(0xFF4CAF50),
                              ),
                              _buildStatItem(
                                'Total Days',
                                _totalDays.toString(),
                                accentColor,
                              ),
                              _buildStatItem(
                                'Leave',
                                (_totalDays - _presentDays).toString(),
                                const Color(0xFFEF5350),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Quick Actions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 1.h),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Quick Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.note_add_rounded,
                          title: 'Leave Request',
                          subtitle: 'Apply for leave',
                          color: accentColor,
                          onTap: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const LeaveRequestForm(),
                            );
                            if (result == true) {
                              _loadData(); // Refresh data after submission
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.business_center_rounded,
                          title: 'On-Duty',
                          subtitle: 'Submit request',
                          color: accentSecondary,
                          onTap: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const OnDutyRequestForm(),
                            );
                            if (result == true) {
                              _loadData(); // Refresh data after submission
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.history_rounded,
                          title: 'Request History',
                          subtitle: 'View all requests',
                          color: const Color(0xFFFFA726),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RequestHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.refresh_rounded,
                          title: 'Refresh',
                          subtitle: 'Update data',
                          color: const Color(0xFF66BB6A),
                          onTap: _loadData,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 10.h),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(3.w),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 6.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}