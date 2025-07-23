import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ReasonDropdownWidget extends StatelessWidget {
  final String? selectedReason;
  final Function(String?) onReasonChanged;
  final String? errorText;

  const ReasonDropdownWidget({
    Key? key,
    required this.selectedReason,
    required this.onReasonChanged,
    this.errorText,
  }) : super(key: key);

  static const List<String> reasons = [
    'Medical',
    'Personal',
    'Emergency',
    'Family',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.cardDark.withValues(alpha: 0.6)
            : AppTheme.cardLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null
              ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
              : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason for Leave',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceDark.withValues(alpha: 0.5)
                  : AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                width: 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedReason,
                hint: Text(
                  'Select reason',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textDisabledDark
                            : AppTheme.textDisabledLight,
                      ),
                ),
                isExpanded: true,
                icon: CustomIconWidget(
                  iconName: 'arrow_drop_down',
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  size: 20,
                ),
                dropdownColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                items: reasons.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: _getReasonIcon(value),
                          color: isDark
                              ? AppTheme.primaryDark
                              : AppTheme.primaryLight,
                          size: 18,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onReasonChanged,
              ),
            ),
          ),
          if (errorText != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _getReasonIcon(String reason) {
    switch (reason) {
      case 'Medical':
        return 'local_hospital';
      case 'Personal':
        return 'person';
      case 'Emergency':
        return 'warning';
      case 'Family':
        return 'family_restroom';
      default:
        return 'info';
    }
  }
}
