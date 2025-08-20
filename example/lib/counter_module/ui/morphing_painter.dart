import 'package:flutter/material.dart';

/// Renders the morphing shape and text for the counter display.
class MorphingPainter extends CustomPainter {
  final Path path;
  final Color color;
  final String text;

  MorphingPainter(
      {required this.path, required this.color, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final bounds = path.getBounds();
    if (bounds.width == 0 || bounds.height == 0) return;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scaleX, scaleY)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    final scaledPath = path.transform(transform.storage);

    canvas.drawShadow(
        scaledPath, Colors.black.withAlpha((255 * 0.5).round()), 4.0, true);
    canvas.drawPath(scaledPath, paint);

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
