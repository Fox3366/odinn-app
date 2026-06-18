import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color  color;
  final double step;
  final double strokeWidth;

  const GridPainter({
    required this.color,
    this.step        = 32.0,
    this.strokeWidth = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = strokeWidth;
    for (double x = 0; x < size.width;  x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(GridPainter o) => o.color != color;
}