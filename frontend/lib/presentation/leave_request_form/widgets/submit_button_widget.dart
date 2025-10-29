import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class SubmitButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool isEnabled;

  const SubmitButtonWidget({
    Key? key,
    required this.isLoading,
    required this.onSubmit,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.cardDark.withValues(alpha: 0.9)
            : AppTheme.cardLight.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: isEnabled && !isLoading ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                      : (isDark
                          ? AppTheme.textDisabledDark
                          : AppTheme.textDisabledLight),
                  foregroundColor: isEnabled
                      ? (isDark
                          ? AppTheme.onPrimaryDark
                          : AppTheme.onPrimaryLight)
                      : (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                  elevation: isEnabled ? 2.0 : 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark
                                    ? AppTheme.onPrimaryDark
                                    : AppTheme.onPrimaryLight,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Submitting...',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.onPrimaryDark
                                      : AppTheme.onPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'send',
                            color: isEnabled
                                ? (isDark
                                    ? AppTheme.onPrimaryDark
                                    : AppTheme.onPrimaryLight)
                                : (isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight),
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Submit Request',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: isEnabled
                                      ? (isDark
                                          ? AppTheme.onPrimaryDark
                                          : AppTheme.onPrimaryLight)
                                      : (isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please review all information before submitting',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
