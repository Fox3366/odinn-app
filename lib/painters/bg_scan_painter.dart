import 'package:flutter/material.dart';

/// Arka planda yavaşça kayan tarama çizgisi efekti.
class BgScanPainter extends CustomPainter {
  final double progress;
  final Color  red;

  const BgScanPainter({required this.progress, required this.red});

  @override
  void paint(Canvas canvas, Size size) {
    final gp = Paint()..color = const Color(0xFF141414)..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width;  x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);

    final scanY = (progress * size.height * 1.4) - size.height * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 60, size.width, 120),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, red.withValues(alpha: 0.025), red.withValues(alpha: 0.04), red.withValues(alpha: 0.025), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, scanY - 60, size.width, 120)),
    );
  }

  @override
  bool shouldRepaint(BgScanPainter o) => o.progress != progress;
}
