import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../core/app_export.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorMessageWidget({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 90.w,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.errorDark : AppTheme.errorLight)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error_outline',
                  color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              isDark ? AppTheme.errorDark : AppTheme.errorLight,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (onDismiss != null) ...[
                  SizedBox(width: 2.w),
                  GestureDetector(
                    onTap: onDismiss,
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
                      size: 4.w,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
