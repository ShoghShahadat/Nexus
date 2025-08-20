import 'dart:math';
import 'package:flutter/material.dart';

/// A utility function to generate a path for a regular polygon or a circle.
Path getPolygonPath(Size size, int sides, {double cornerRadius = 0.0}) {
  final path = Path();
  final radius = min(size.width, size.height) / 2;
  final centerX = size.width / 2;
  final centerY = size.height / 2;
  final angle = (pi * 2) / sides;

  // If the number of sides is large, approximate it with a circle.
  if (sides > 20) {
    return path
      ..addOval(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
  }

  // If it's a rectangle with a corner radius, use RRect.
  if (sides == 4 && cornerRadius > 0) {
    return path
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius)));
  }

  // Generate points for the polygon.
  final points = <Offset>[];
  for (int i = 0; i < sides; i++) {
    final x = centerX + cos(i * angle - pi / 2) * radius;
    final y = centerY + sin(i * angle - pi / 2) * radius;
    points.add(Offset(x, y));
  }

  // Create the path from the points.
  path.moveTo(points.last.dx, points.last.dy);
  for (final point in points) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  return path;
}
