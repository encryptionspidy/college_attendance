import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DescriptionInputWidget extends StatefulWidget {
  final String? description;
  final Function(String) onDescriptionChanged;
  final String? errorText;

  const DescriptionInputWidget({
    Key? key,
    required this.description,
    required this.onDescriptionChanged,
    this.errorText,
  }) : super(key: key);

  @override
  State<DescriptionInputWidget> createState() => _DescriptionInputWidgetState();
}

class _DescriptionInputWidgetState extends State<DescriptionInputWidget> {
  late TextEditingController _controller;
  static const int maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.description ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLength = _controller.text.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.cardDark.withValues(alpha: 0.6)
            : AppTheme.cardLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.errorText != null
              ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
              : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detailed Explanation',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '$currentLength/$maxCharacters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: currentLength > maxCharacters
                          ? (isDark ? AppTheme.errorDark : AppTheme.errorLight)
                          : (isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight),
                    ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 12.h,
              maxHeight: 20.h,
            ),
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
            child: TextField(
              controller: _controller,
              maxLines: null,
              maxLength: maxCharacters,
              textInputAction: TextInputAction.newline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
              decoration: InputDecoration(
                hintText:
                    'Please provide detailed explanation for your leave request...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textDisabledDark
                          : AppTheme.textDisabledLight,
                    ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(4.w),
                counterText: '',
              ),
              onChanged: (value) {
                setState(() {});
                widget.onDescriptionChanged(value);
              },
            ),
          ),
          if (widget.errorText != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
