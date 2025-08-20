import 'package:flutter/material.dart';

/// A custom painter for rendering the animated bar chart.
class BarChartPainter extends CustomPainter {
  final List<double> values;
  final double animationProgress; // A value from 0.0 to 1.0

  BarChartPainter({required this.values, required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final double barSpacing = size.width * 0.05;
    final double totalSpacing = barSpacing * (values.length + 1);
    final double barWidth = (size.width - totalSpacing) / values.length;
    final double maxVal = values.reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < values.length; i++) {
      final left = barSpacing + (barWidth + barSpacing) * i;
      final barHeight = (values[i] / maxVal) * size.height;

      // Animate the height of the bar based on the progress.
      final animatedHeight = barHeight * animationProgress;

      final rect = Rect.fromLTWH(
          left, size.height - animatedHeight, barWidth, animatedHeight);

      // Simple gradient for visual appeal.
      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.blue.shade700, Colors.blue.shade300],
      ).createShader(rect);

      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    // Repaint whenever the animation progress changes.
    return oldDelegate.animationProgress != animationProgress;
  }
}
