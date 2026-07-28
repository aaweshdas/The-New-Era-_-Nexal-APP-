import 'dart:math' as math;
import 'package:flutter/material.dart';

class SnapCaptureButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final double progress; // 0.0 to 1.0
  final bool isRecording;

  const SnapCaptureButton({
    super.key,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.progress,
    required this.isRecording,
  });

  @override
  State<SnapCaptureButton> createState() => _SnapCaptureButtonState();
}

class _SnapCaptureButtonState extends State<SnapCaptureButton> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _animCtrl.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _animCtrl.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPressStart: (_) {
        _animCtrl.forward();
        widget.onLongPressStart();
      },
      onLongPressEnd: (_) {
        _animCtrl.reverse();
        widget.onLongPressEnd();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (ctx, child) {
          return Transform.scale(
            scale: widget.isRecording ? 1.15 : _scaleAnim.value,
            child: SizedBox(
              width: 84,
              height: 84,
              child: CustomPaint(
                painter: _SnapButtonPainter(
                  progress: widget.progress,
                  isRecording: widget.isRecording,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SnapButtonPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  _SnapButtonPainter({
    required this.progress,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 4;
    final innerRadius = outerRadius - 6;

    // 1. Outer Ring (White, 3px stroke)
    final outerPaint = Paint()
      ..color = isRecording ? const Color(0xFFFF2A4B) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // 2. Inner Fill (Semi-transparent white or solid red on record)
    final innerPaint = Paint()
      ..color = isRecording
          ? const Color(0xFFFF2A4B).withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // 3. Red Progress Arc when recording (0 to 60s)
    if (isRecording && progress > 0.0) {
      final progressPaint = Paint()
        ..color = const Color(0xFFFF0033)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.0;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius + 2),
        -math.pi / 2, // Start at top center (12 o'clock)
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnapButtonPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isRecording != isRecording;
  }
}
