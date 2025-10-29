import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../../core/app_export.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconName;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: backgroundColor?.withValues(alpha: 0.1) ??
                    (isDark
                        ? AppTheme.glassOverlay.withValues(alpha: 0.1)
                        : AppTheme.glassOverlay.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: backgroundColor?.withValues(alpha: 0.3) ??
                      (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: backgroundColor?.withValues(alpha: 0.2) ??
                          (isDark
                                  ? AppTheme.primaryDark
                                  : AppTheme.primaryLight)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: iconName,
                        color: backgroundColor ??
                            (isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight),
                        size: 6.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
