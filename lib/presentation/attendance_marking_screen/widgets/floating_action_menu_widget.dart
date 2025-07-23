import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FloatingActionMenuWidget extends StatefulWidget {
  final VoidCallback onMarkAllPresent;
  final VoidCallback onMarkAllAbsent;
  final VoidCallback onShowSummary;

  const FloatingActionMenuWidget({
    Key? key,
    required this.onMarkAllPresent,
    required this.onMarkAllAbsent,
    required this.onShowSummary,
  }) : super(key: key);

  @override
  State<FloatingActionMenuWidget> createState() =>
      _FloatingActionMenuWidgetState();
}

class _FloatingActionMenuWidgetState extends State<FloatingActionMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mark All Present Button
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: FloatingActionButton(
                    heroTag: "markAllPresent",
                    onPressed: _isExpanded
                        ? () {
                            widget.onMarkAllPresent();
                            _toggleMenu();
                          }
                        : null,
                    backgroundColor: AppTheme.presentStatus,
                    foregroundColor: Colors.white,
                    child: CustomIconWidget(
                      iconName: 'check_circle',
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Mark All Absent Button
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: FloatingActionButton(
                    heroTag: "markAllAbsent",
                    onPressed: _isExpanded
                        ? () {
                            widget.onMarkAllAbsent();
                            _toggleMenu();
                          }
                        : null,
                    backgroundColor: AppTheme.absentStatus,
                    foregroundColor: Colors.white,
                    child: CustomIconWidget(
                      iconName: 'cancel',
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Show Summary Button
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: FloatingActionButton(
                    heroTag: "showSummary",
                    onPressed: _isExpanded
                        ? () {
                            widget.onShowSummary();
                            _toggleMenu();
                          }
                        : null,
                    backgroundColor:
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    foregroundColor: isDark
                        ? AppTheme.onPrimaryDark
                        : AppTheme.onPrimaryLight,
                    child: CustomIconWidget(
                      iconName: 'analytics',
                      color: isDark
                          ? AppTheme.onPrimaryDark
                          : AppTheme.onPrimaryLight,
                      size: 6.w,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Main FAB
        FloatingActionButton(
          heroTag: "mainFAB",
          onPressed: _toggleMenu,
          backgroundColor:
              isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
          foregroundColor:
              isDark ? AppTheme.onSecondaryDark : AppTheme.onSecondaryLight,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: CustomIconWidget(
              iconName: _isExpanded ? 'close' : 'more_vert',
              color:
                  isDark ? AppTheme.onSecondaryDark : AppTheme.onSecondaryLight,
              size: 6.w,
            ),
          ),
        ),
      ],
    );
  }
}
