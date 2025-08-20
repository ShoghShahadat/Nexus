import 'dart:math';
import 'package:flutter/material.dart';

/// Renders the shape selection buttons.
class ShapeButtonPainter extends CustomPainter {
  final Path path;
  ShapeButtonPainter({required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final bounds = path.getBounds();
    if (bounds.width == 0 || bounds.height == 0) return;

    final scale =
        min(size.width / bounds.width, size.height / bounds.height) * 0.8;
    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale, scale)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    final scaledPath = path.transform(transform.storage);

    canvas.drawPath(scaledPath, paint);
    canvas.drawPath(scaledPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
