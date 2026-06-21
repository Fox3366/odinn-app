import 'package:flutter/material.dart';

class HudCornerPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double strokeWidth;
  final double cornerLen;
  final double pad;

  const HudCornerPainter({
    required this.color,
    this.opacity     = 0.7,
    this.strokeWidth = 2.0,
    this.cornerLen   = 28.0,
    this.pad         = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color      = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style      = PaintingStyle.stroke;
    final l = cornerLen;
    final d = pad;
    canvas.drawPath(Path()..moveTo(d, d+l)..lineTo(d, d)..lineTo(d+l, d), p);
    canvas.drawPath(Path()..moveTo(size.width-d-l, d)..lineTo(size.width-d, d)..lineTo(size.width-d, d+l), p);
    canvas.drawPath(Path()..moveTo(d, size.height-d-l)..lineTo(d, size.height-d)..lineTo(d+l, size.height-d), p);
    canvas.drawPath(Path()..moveTo(size.width-d-l, size.height-d)..lineTo(size.width-d, size.height-d)..lineTo(size.width-d, size.height-d-l), p);
  }

  @override
  bool shouldRepaint(HudCornerPainter o) => o.color != color;
}
