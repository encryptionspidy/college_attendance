import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ImageAttachmentWidget extends StatefulWidget {
  final List<String> attachedImages;
  final Function(List<String>) onImagesChanged;

  const ImageAttachmentWidget({
    Key? key,
    required this.attachedImages,
    required this.onImagesChanged,
  }) : super(key: key);

  @override
  State<ImageAttachmentWidget> createState() => _ImageAttachmentWidgetState();
}

class _ImageAttachmentWidgetState extends State<ImageAttachmentWidget> {
  final ImagePicker _picker = ImagePicker();
  static const int maxImages = 3;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

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
          color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
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
                'Attach Documents',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '${widget.attachedImages.length}/$maxImages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (widget.attachedImages.isEmpty) ...[
            _buildEmptyState(isDark),
          ] else ...[
            _buildImageGrid(isDark),
            SizedBox(height: 2.h),
          ],
          if (widget.attachedImages.length < maxImages) ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Camera',
                    'camera_alt',
                    () => _pickImage(ImageSource.camera),
                    isDark,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Gallery',
                    'photo_library',
                    () => _pickImage(ImageSource.gallery),
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      height: 15.h,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withValues(alpha: 0.3)
            : AppTheme.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'cloud_upload',
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            size: 32,
          ),
          SizedBox(height: 1.h),
          Text(
            'No documents attached',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
          ),
          Text(
            'Tap camera or gallery to add',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.textDisabledDark
                      : AppTheme.textDisabledLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(bool isDark) {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: widget.attachedImages.asMap().entries.map((entry) {
        final index = entry.key;
        final base64Image = entry.value;

        return Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
              width: 1.0,
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.memory(
                  base64Decode(base64Image),
                  width: 25.w,
                  height: 25.w,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 1.w,
                right: 1.w,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    String iconName,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryDark.withValues(alpha: 0.1)
              : AppTheme.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions
      bool hasPermission = await _requestPermission(source);
      if (!hasPermission) {
        _showErrorMessage(
            'Permission denied. Please enable camera/gallery access in settings.');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();

        // Check file size
        if (imageBytes.length > maxFileSizeBytes) {
          _showErrorMessage(
              'Image size too large. Please select an image smaller than 5MB.');
          return;
        }

        final String base64Image = base64Encode(imageBytes);
        final List<String> updatedImages = List.from(widget.attachedImages)
          ..add(base64Image);

        widget.onImagesChanged(updatedImages);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image. Please try again.');
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (kIsWeb) return true;

    Permission permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    PermissionStatus status = await permission.request();
    return status.isGranted;
  }

  void _removeImage(int index) {
    final List<String> updatedImages = List.from(widget.attachedImages)
      ..removeAt(index);
    widget.onImagesChanged(updatedImages);
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.errorDark
              : AppTheme.errorLight,
        ),
      );
    }
  }
}
