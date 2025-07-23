import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SignaturePadModal extends StatefulWidget {
  final Function(List<Offset>) onSignatureComplete;

  const SignaturePadModal({
    Key? key,
    required this.onSignatureComplete,
  }) : super(key: key);

  @override
  State<SignaturePadModal> createState() => _SignaturePadModalState();
}

class _SignaturePadModalState extends State<SignaturePadModal> {
  List<Offset> _signaturePoints = [];
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(4.w),
          height: 70.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildSignaturePad(context, isDark),
              ),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'draw',
            color: Colors.white,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Signature',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Please sign to approve the request',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: CustomIconWidget(
              iconName: 'close',
              color: Colors.white,
              size: 6.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePad(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isDrawing = true;
              _signaturePoints.add(details.localPosition);
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _signaturePoints.add(details.localPosition);
            });
          },
          onPanEnd: (details) {
            setState(() {
              _isDrawing = false;
              _signaturePoints.add(Offset.infinite);
            });
          },
          child: CustomPaint(
            painter: SignaturePainter(
              points: _signaturePoints,
              strokeColor: isDark ? Colors.white : Colors.black,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearSignature,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 4.w,
              ),
              label: Text('Clear'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _signaturePoints.isNotEmpty ? _confirmSignature : null,
              icon: CustomIconWidget(
                iconName: 'check',
                color: Colors.white,
                size: 4.w,
              ),
              label: Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.presentStatus,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSignature() {
    setState(() {
      _signaturePoints.clear();
    });
  }

  void _confirmSignature() {
    if (_signaturePoints.isNotEmpty) {
      widget.onSignatureComplete(_signaturePoints);
      Navigator.of(context).pop();
    }
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;
  final Color strokeColor;

  SignaturePainter({
    required this.points,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
