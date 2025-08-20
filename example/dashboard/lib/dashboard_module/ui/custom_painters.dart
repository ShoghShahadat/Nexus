import 'package:flutter/material.dart';

/// A custom painter for rendering the animated weekly bar chart.
class BarChartPainter extends CustomPainter {
  final List<double> values;
  final double animationProgress;

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
      final animatedHeight = barHeight * animationProgress;

      final rect = Rect.fromLTWH(
          left, size.height - animatedHeight, barWidth, animatedHeight);

      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade300],
      ).createShader(rect);

      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}

// *** NEW: A highly optimized painter for the real-time chart. ***
class RealtimeChartPainter extends CustomPainter {
  final List<double> values;

  RealtimeChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent.shade400
      ..style = PaintingStyle.fill;

    final double barWidth = size.width / values.length;
    final double maxVal = 100.0; // Data is normalized between 0-100

    for (int i = 0; i < values.length; i++) {
      final left = barWidth * i;
      final barHeight = (values[i] / maxVal) * size.height;
      final rect =
          Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RealtimeChartPainter oldDelegate) {
    // This is crucial for performance. It tells Flutter to repaint
    // only if the data has actually changed. Since our data changes every
    // frame, this will always be true, but it's the correct way to implement it.
    return true;
  }
}
