import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class SettingsWidget extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onDarkModeChanged;
  final VoidCallback? onProfilePhotoUpdate;

  const SettingsWidget({
    Key? key,
    required this.isDarkMode,
    this.onDarkModeChanged,
    this.onProfilePhotoUpdate,
  }) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget>
    with TickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
                SizedBox(height: 2.h),
                _buildSettingsSection(
                  context,
                  'Profile',
                  [
                    _buildSettingsTile(
                      context,
                      'Update Profile Photo',
                      'Change your profile picture',
                      'photo_camera',
                      onTap: widget.onProfilePhotoUpdate ??
                          () => _updateProfilePhoto(context),
                      isDark: isDark,
                    ),
                    _buildSettingsTile(
                      context,
                      'Edit Profile',
                      'Update your personal information',
                      'edit',
                      onTap: () => _editProfile(context),
                      isDark: isDark,
                    ),
                  ],
                  isDark,
                ),
                SizedBox(height: 2.h),
                _buildSettingsSection(
                  context,
                  'Notifications',
                  [
                    _buildSwitchTile(
                      context,
                      'Enable Notifications',
                      'Receive attendance and leave updates',
                      'notifications',
                      _notificationsEnabled,
                      (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      isDark,
                    ),
                    _buildSwitchTile(
                      context,
                      'Email Notifications',
                      'Get updates via email',
                      'email',
                      _emailNotifications,
                      (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                      isDark,
                    ),
                    _buildSwitchTile(
                      context,
                      'Push Notifications',
                      'Receive push notifications',
                      'notifications_active',
                      _pushNotifications,
                      (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                      isDark,
                    ),
                  ],
                  isDark,
                ),
                SizedBox(height: 2.h),
                _buildSettingsSection(
                  context,
                  'Appearance',
                  [
                    _buildSwitchTile(
                      context,
                      'Dark Mode',
                      'Switch between light and dark theme',
                      widget.isDarkMode ? 'dark_mode' : 'light_mode',
                      widget.isDarkMode,
                      (value) {
                        _animationController.forward().then((_) {
                          widget.onDarkModeChanged?.call(value);
                          _animationController.reverse();
                        });
                      },
                      isDark,
                    ),
                  ],
                  isDark,
                ),
                SizedBox(height: 2.h),
                _buildSettingsSection(
                  context,
                  'Data & Privacy',
                  [
                    _buildSettingsTile(
                      context,
                      'Export Data',
                      'Download your attendance data',
                      'download',
                      onTap: () => _exportData(context),
                      isDark: isDark,
                    ),
                    _buildSettingsTile(
                      context,
                      'Privacy Policy',
                      'Read our privacy policy',
                      'privacy_tip',
                      onTap: () => _showPrivacyPolicy(context),
                      isDark: isDark,
                    ),
                    _buildSettingsTile(
                      context,
                      'Clear Cache',
                      'Clear app cache and temporary data',
                      'clear_all',
                      onTap: () => _clearCache(context),
                      isDark: isDark,
                    ),
                  ],
                  isDark,
                ),
                SizedBox(height: 2.h),
                _buildSettingsSection(
                  context,
                  'Support',
                  [
                    _buildSettingsTile(
                      context,
                      'Help & Support',
                      'Get help and contact support',
                      'help',
                      onTap: () => _showHelp(context),
                      isDark: isDark,
                    ),
                    _buildSettingsTile(
                      context,
                      'About',
                      'App version and information',
                      'info',
                      onTap: () => _showAbout(context),
                      isDark: isDark,
                    ),
                  ],
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.cardDark : AppTheme.cardLight)
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    String iconName, {
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            size: 20,
          ),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
      ),
      trailing: CustomIconWidget(
        iconName: 'chevron_right',
        color:
            isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    String iconName,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return ListTile(
      leading: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            size: 20,
          ),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
      ),
      trailing: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animationController.value * 0.1),
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }

  void _updateProfilePhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPhotoOptions(context),
    );
  }

  Widget _buildPhotoOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Update Profile Photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
          ),
          SizedBox(height: 2.h),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'photo_camera',
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              size: 24,
            ),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto(context);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'photo_library',
              color: isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
              size: 24,
            ),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _chooseFromGallery(context);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'delete',
              color: AppTheme.absentStatus,
              size: 24,
            ),
            title: const Text('Remove Photo'),
            onTap: () {
              Navigator.pop(context);
              _removePhoto(context);
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing feature coming soon...'),
        backgroundColor: AppTheme.onDutyStatus,
      ),
    );
  }

  void _takePhoto(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera opened successfully'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _chooseFromGallery(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery opened successfully'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _removePhoto(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile photo removed'),
        backgroundColor: AppTheme.absentStatus,
      ),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started...'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a sample privacy policy. In a real application, this would contain the actual privacy policy text explaining how user data is collected, used, and protected.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'Are you sure you want to clear the app cache? This will remove temporary files and may improve performance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppTheme.presentStatus,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HelpScreen(),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'College Attendance Marker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 15.w,
        height: 15.w,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'school',
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
      children: [
        const Text(
            'A comprehensive attendance management system for college students and faculty.'),
        SizedBox(height: 2.h),
        const Text('Features:'),
        const Text('• Attendance tracking and statistics'),
        const Text('• Leave request management'),
        const Text('• Digital signature support'),
        const Text('• Offline functionality'),
        const Text('• Data export capabilities'),
      ],
    );
  }
}

class _HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpSection(
              context,
              'Getting Started',
              [
                'How to mark attendance',
                'Submitting leave requests',
                'Viewing attendance statistics',
                'Understanding attendance status',
              ],
              isDark,
            ),
            SizedBox(height: 2.h),
            _buildHelpSection(
              context,
              'Features',
              [
                'Calendar view navigation',
                'Downloading reports',
                'Profile management',
                'Notification settings',
              ],
              isDark,
            ),
            SizedBox(height: 2.h),
            _buildHelpSection(
              context,
              'Troubleshooting',
              [
                'App not syncing data',
                'Login issues',
                'Notification problems',
                'Performance issues',
              ],
              isDark,
            ),
            SizedBox(height: 3.h),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening support chat...'),
                      backgroundColor: AppTheme.presentStatus,
                    ),
                  );
                },
                child: const Text('Contact Support'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(
      BuildContext context, String title, List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
        ),
        SizedBox(height: 1.h),
        ...items
            .map((item) => ListTile(
                  leading: CustomIconWidget(
                    iconName: 'help_outline',
                    color:
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    size: 20,
                  ),
                  title: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    size: 16,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Help topic: $item'),
                        backgroundColor: AppTheme.onDutyStatus,
                      ),
                    );
                  },
                ))
            .toList(),
      ],
    );
  }
}
