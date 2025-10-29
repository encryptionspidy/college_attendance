import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LoginFormWidget extends StatefulWidget {
  final Function(String username, String password, bool rememberMe) onLogin;
  final bool isLoading;

  const LoginFormWidget({
    super.key,
    required this.onLogin,
    required this.isLoading,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) {
    setState(() {
      if (value.isEmpty) {
        _usernameError = 'Username is required';
      } else if (value.length < 3) {
        _usernameError = 'Username must be at least 3 characters';
      } else {
        _usernameError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Password is required';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  bool get _isFormValid {
    return _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _usernameError == null &&
        _passwordError == null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 90.w,
      decoration: AppTheme.glassmorphismDecoration(
        isLight: !isDark,
        borderRadius: 16.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(6.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Sign in to access your attendance portal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                  SizedBox(height: 4.h),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    onChanged: _validateUsername,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          size: 5.w,
                        ),
                      ),
                      errorText: _usernameError,
                      errorStyle: TextStyle(
                        color:
                            isDark ? AppTheme.errorDark : AppTheme.errorLight,
                        fontSize: 12.sp,
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 3.h),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    onChanged: _validatePassword,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'lock',
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          size: 5.w,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        icon: CustomIconWidget(
                          iconName: _isPasswordVisible
                              ? 'visibility_off'
                              : 'visibility',
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          size: 5.w,
                        ),
                      ),
                      errorText: _passwordError,
                      errorStyle: TextStyle(
                        color:
                            isDark ? AppTheme.errorDark : AppTheme.errorLight,
                        fontSize: 12.sp,
                      ),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_isFormValid && !widget.isLoading) {
                        widget.onLogin(_usernameController.text,
                            _passwordController.text, _rememberMe);
                      }
                    },
                  ),
                  SizedBox(height: 3.h),

                  // Remember Me Toggle
                  Row(
                    children: [
                      Switch(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value;
                          });
                        },
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Remember Me',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !widget.isLoading
                          ? () => widget.onLogin(_usernameController.text,
                              _passwordController.text, _rememberMe)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? (isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight)
                            : (isDark
                                ? AppTheme.textDisabledDark
                                : AppTheme.textDisabledLight),
                        foregroundColor: _isFormValid
                            ? (isDark
                                ? AppTheme.onPrimaryDark
                                : AppTheme.onPrimaryLight)
                            : (isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight),
                        elevation: _isFormValid ? 2.0 : 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: widget.isLoading
                          ? SizedBox(
                              width: 5.w,
                              height: 5.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? AppTheme.onPrimaryDark
                                      : AppTheme.onPrimaryLight,
                                ),
                              ),
                            )
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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
