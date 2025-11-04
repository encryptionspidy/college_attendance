import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A glassmorphic button with smooth animations and haptic feedback
/// 
/// Features:
/// - Smooth press animation (scale + opacity)
/// - Glass ripple effect
/// - Loading state with spinner
/// - Haptic feedback on press
/// - Icon support
/// - Customizable colors and size
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double height;
  final double? width;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool enabled;

  const GlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.color,
    this.textColor,
    this.height = 50,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.borderRadius,
    this.elevation = 8.0,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.loading) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && !widget.loading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && !widget.loading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final buttonColor = widget.color ??
        (isDark ? const Color(0xFF4A90E2) : const Color(0xFF3F51B5));
    
    final buttonTextColor = widget.textColor ?? Colors.white;
    final isInteractive = widget.enabled && !widget.loading;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: isInteractive ? widget.onPressed : null,
              child: Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  boxShadow: isInteractive
                      ? [
                          BoxShadow(
                            color: buttonColor.withOpacity(0.4),
                            blurRadius: widget.elevation,
                            offset: Offset(0, widget.elevation / 2),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isInteractive
                              ? [
                                  buttonColor.withOpacity(0.8),
                                  buttonColor.withOpacity(0.6),
                                ]
                              : [
                                  buttonColor.withOpacity(0.4),
                                  buttonColor.withOpacity(0.3),
                                ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      padding: widget.padding,
                      child: _buildContent(buttonTextColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(Color textColor) {
    if (widget.loading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A compact glass button for secondary actions
class GlassButtonSecondary extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const GlassButtonSecondary({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      loading: loading,
      height: 45,
      color: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
      elevation: 4.0,
    );
  }
}

/// An icon-only glass button
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const GlassIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withOpacity(0.15),
              borderRadius: BorderRadius.circular(size / 4),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : Colors.black87,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
