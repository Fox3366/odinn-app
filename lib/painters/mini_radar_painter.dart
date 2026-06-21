import 'dart:math';
import 'package:flutter/material.dart';

/// Ana ekranın video alanında gösterilen küçük radar.
class MiniRadarPainter extends CustomPainter {
  final double angle;
  final Color  red;

  const MiniRadarPainter({required this.angle, required this.red});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 3,
          Paint()..style = PaintingStyle.stroke..color = red.withValues(alpha: 0.08)..strokeWidth = 1);
    }
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), Paint()..color = red.withValues(alpha: 0.08)..strokeWidth = 0.7);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), Paint()..color = red.withValues(alpha: 0.08)..strokeWidth = 0.7);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..shader = SweepGradient(
          startAngle: angle - 1.0, endAngle: angle,
          colors: [Colors.transparent, red.withValues(alpha: 0.3)],
          center: Alignment.center,
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawLine(Offset(cx, cy), Offset(cx + cos(angle) * r, cy + sin(angle) * r),
        Paint()..color = red.withValues(alpha: 0.5)..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(MiniRadarPainter o) => true;
}
