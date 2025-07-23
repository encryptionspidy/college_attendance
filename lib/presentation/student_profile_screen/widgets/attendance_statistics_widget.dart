import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AttendanceStatisticsWidget extends StatefulWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceStatisticsWidget({
    Key? key,
    required this.attendanceData,
  }) : super(key: key);

  @override
  State<AttendanceStatisticsWidget> createState() =>
      _AttendanceStatisticsWidgetState();
}

class _AttendanceStatisticsWidgetState extends State<AttendanceStatisticsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overallPercentage =
        (widget.attendanceData['overallPercentage'] as num?)?.toDouble() ??
            85.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppTheme.glassmorphismDecoration(isLight: !isDark),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildOverallProgress(
                          context, overallPercentage, isDark),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 3,
                      child: _buildSubjectBreakdown(context, isDark),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                _buildMonthlyChart(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(
      BuildContext context, double percentage, bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 25.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 35.w,
                height: 35.w,
                child: CircularProgressIndicator(
                  value: _animation.value * (percentage / 100),
                  strokeWidth: 8,
                  backgroundColor:
                      (isDark ? AppTheme.dividerDark : AppTheme.dividerLight)
                          .withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 75
                        ? AppTheme.presentStatus
                        : percentage >= 50
                            ? AppTheme.onDutyStatus
                            : AppTheme.absentStatus,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(percentage * _animation.value).toInt()}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                  Text(
                    'Overall',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectBreakdown(BuildContext context, bool isDark) {
    final subjects = (widget.attendanceData['subjects'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [
          {
            'name': 'Mathematics',
            'percentage': 88.0,
            'present': 44,
            'total': 50
          },
          {'name': 'Physics', 'percentage': 82.0, 'present': 41, 'total': 50},
          {'name': 'Chemistry', 'percentage': 90.0, 'present': 45, 'total': 50},
          {'name': 'English', 'percentage': 85.0, 'present': 42, 'total': 49},
        ];

    return Column(
      children: subjects.map((subject) {
        final percentage = (subject['percentage'] as num?)?.toDouble() ?? 0.0;
        final present = subject['present'] as int? ?? 0;
        final total = subject['total'] as int? ?? 0;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject['name'] as String? ?? 'Subject',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: percentage >= 75
                              ? AppTheme.presentStatus
                              : percentage >= 50
                                  ? AppTheme.onDutyStatus
                                  : AppTheme.absentStatus,
                        ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animation.value * (percentage / 100),
                    backgroundColor:
                        (isDark ? AppTheme.dividerDark : AppTheme.dividerLight)
                            .withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 75
                          ? AppTheme.presentStatus
                          : percentage >= 50
                              ? AppTheme.onDutyStatus
                              : AppTheme.absentStatus,
                    ),
                  );
                },
              ),
              SizedBox(height: 0.5.h),
              Text(
                '$present/$total classes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, bool isDark) {
    final monthlyData = (widget.attendanceData['monthlyTrends'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [
          {'month': 'Jan', 'percentage': 85.0},
          {'month': 'Feb', 'percentage': 88.0},
          {'month': 'Mar', 'percentage': 82.0},
          {'month': 'Apr', 'percentage': 90.0},
          {'month': 'May', 'percentage': 87.0},
          {'month': 'Jun', 'percentage': 85.0},
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trends',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 25.h,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color:
                        (isDark ? AppTheme.dividerDark : AppTheme.dividerLight)
                            .withValues(alpha: 0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      );
                    },
                    reservedSize: 10.w,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < monthlyData.length) {
                        return Text(
                          monthlyData[value.toInt()]['month'] as String,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (monthlyData.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: monthlyData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      (entry.value['percentage'] as num).toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight,
                        strokeWidth: 2,
                        strokeColor: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceLight,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                            .withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()}%',
                        TextStyle(
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
