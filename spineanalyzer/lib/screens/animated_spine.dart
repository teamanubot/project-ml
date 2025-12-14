import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedSpine extends StatefulWidget {
  const AnimatedSpine({super.key});
  @override
  State<AnimatedSpine> createState() => _AnimatedSpineState();
}

class _AnimatedSpineState extends State<AnimatedSpine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: SpinePainter(_controller.value),
          );
        },
      ),
    );
  }
}

class SpinePainter extends CustomPainter {
  final double progress;
  SpinePainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final vertebraeCount = 8;
    final paint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = const Color(0x331976D2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final centerX = size.width / 2;
    final baseY = 30.0;
    for (int i = 0; i < vertebraeCount; i++) {
      final y = baseY + i * 18.0;
      final wave = math.sin(progress * 2 * math.pi + i * 0.7) * 10;
      final vertebraWidth = 38 - i * 2.5;
      final vertebraHeight = 16.0 - i * 0.7;
      final rect = Rect.fromCenter(
        center: Offset(centerX + wave, y),
        width: vertebraWidth,
        height: vertebraHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(vertebraHeight / 2)),
        shadowPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(vertebraHeight / 2)),
        paint,
      );
    }
    // Draw spinal cord
    final cordPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(centerX, baseY - 10);
    for (int i = 0; i < vertebraeCount + 2; i++) {
      final y = baseY - 10 + i * 18.0;
      final wave = math.sin(progress * 2 * math.pi + i * 0.7) * 7;
      path.lineTo(centerX + wave, y);
    }
    canvas.drawPath(path, cordPaint);
  }
  @override
  bool shouldRepaint(covariant SpinePainter oldDelegate) => oldDelegate.progress != progress;
}
