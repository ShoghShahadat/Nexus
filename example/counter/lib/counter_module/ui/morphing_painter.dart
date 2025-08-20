import 'package:flutter/material.dart';

/// Renders the morphing shape and text for the counter display.
/// It now supports cross-fading between two paths for a smooth transition.
class MorphingPainter extends CustomPainter {
  final Path startPath;
  final Path endPath;
  final double progress;
  final Color color;
  final String text;

  MorphingPainter({
    required this.startPath,
    required this.endPath,
    required this.progress,
    required this.color,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Path Scaling ---
    final bounds = endPath.getBounds();
    if (bounds.width == 0 || bounds.height == 0) return;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scaleX, scaleY)
      ..translate(-bounds.center.dx, -bounds.center.dy);

    final scaledStartPath = startPath.transform(transform.storage);
    final scaledEndPath = endPath.transform(transform.storage);

    // --- Cross-Fade Painting ---
    // Draw the starting path, fading it out as progress increases.
    final startPaint = Paint()
      ..color = color.withOpacity(1.0 - progress)
      ..style = PaintingStyle.fill;
    canvas.drawShadow(scaledStartPath, Colors.black.withAlpha(100), 4.0, true);
    canvas.drawPath(scaledStartPath, startPaint);

    // Draw the ending path, fading it in as progress increases.
    final endPaint = Paint()
      ..color = color.withOpacity(progress)
      ..style = PaintingStyle.fill;
    canvas.drawShadow(scaledEndPath, Colors.black.withAlpha(100), 4.0, true);
    canvas.drawPath(scaledEndPath, endPaint);

    // --- Text Painting ---
    final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
    final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: size.width);
    final offset = Offset((size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MorphingPainter oldDelegate) => true;
}
