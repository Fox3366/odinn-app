import 'dart:math';
import 'package:flutter/material.dart';

/// Splash ekranında gösterilen büyük dönen radar efekti.
class RadarPainter extends CustomPainter {
  final double angle, ringProgress, pulse;
  final Color  red, redL;

  const RadarPainter({
    required this.angle,
    required this.ringProgress,
    required this.pulse,
    required this.red,
    required this.redL,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = size.width / 2;

    final ringPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final r = maxR * (i / 4) * ringProgress;
      ringPaint.color = red.withValues(alpha: i == 4 ? 0.25 : 0.12);
      canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    }

    final chPaint = Paint()..color = red.withValues(alpha: 0.2)..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), chPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), chPaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.2, endAngle: angle,
        colors: [Colors.transparent, red.withValues(alpha: 0.5)],
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR));
    canvas.drawCircle(Offset(cx, cy), maxR * ringProgress, sweepPaint);

    canvas.drawLine(
      Offset(cx, cy), Offset(cx + cos(angle) * maxR, cy + sin(angle) * maxR),
      Paint()..color = redL.withValues(alpha: 0.85)..strokeWidth = 1.5,
    );

    canvas.drawCircle(Offset(cx, cy), 4 * pulse,
        Paint()..color = red.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = const Color(0xFF8B0000));
  }

  @override
  bool shouldRepaint(RadarPainter o) => true;
}
