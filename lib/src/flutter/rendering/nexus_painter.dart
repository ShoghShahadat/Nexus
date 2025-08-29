import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';

/// A custom painter that interprets a render packet (a list of declarative
/// drawing commands) and translates them into imperative canvas calls.
/// It also handles hit-testing against the described scene graph.
class NexusPainter extends CustomPainter {
  final List<Map<String, dynamic>> renderPacket;
  final FlutterRenderingSystem renderingSystem;

  NexusPainter({required this.renderPacket, required this.renderingSystem})
      : super(repaint: renderingSystem);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Optional: Clip to the bounds of the widget.
    canvas.clipRect(Offset.zero & size);

    for (final command in renderPacket) {
      canvas.save();

      // Apply transform
      final transform = command['transform'] as Map<String, dynamic>;
      canvas.translate((transform['x'] as num).toDouble(),
          (transform['y'] as num).toDouble());
      final scale = (transform['scale'] as num).toDouble();
      canvas.scale(scale, scale);
      // TODO: Apply rotation

      final shape = command['shape'] as Map<String, dynamic>;
      final style = command['style'] as Map<String, dynamic>;

      final paint = _createPaint(style);

      // Draw shape
      _drawShape(canvas, shape, paint);

      canvas.restore();
    }
    canvas.restore();
  }

  Paint _createPaint(Map<String, dynamic> style) {
    final paint = Paint();
    paint.style = PaintingStyle.values[style['style'] as int];
    paint.strokeWidth = (style['strokeWidth'] as num).toDouble();
    paint.strokeCap = StrokeCap.values[style['strokeCap'] as int];
    paint.strokeJoin = StrokeJoin.values[style['strokeJoin'] as int];

    final colorData = style['color'] as Map<String, dynamic>;
    if (colorData['type'] == 'solid') {
      paint.color = Color(colorData['value'] as int);
    } else if (colorData['type'] == 'gradient') {
      paint.shader = ui.Gradient.linear(
        Offset((colorData['beginX'] as num).toDouble(),
            (colorData['beginY'] as num).toDouble()),
        Offset((colorData['endX'] as num).toDouble(),
            (colorData['endY'] as num).toDouble()),
        (colorData['colors'] as List).cast<int>().map((c) => Color(c)).toList(),
        (colorData['stops'] as List).cast<double>(),
      );
    }

    return paint;
  }

  void _drawShape(Canvas canvas, Map<String, dynamic> shape, Paint paint) {
    switch (shape['type']) {
      case 'rectangle':
        final rect = Rect.fromLTWH(
          (shape['x'] as num).toDouble(),
          (shape['y'] as num).toDouble(),
          (shape['width'] as num).toDouble(),
          (shape['height'] as num).toDouble(),
        );
        final radius = (shape['cornerRadius'] as num).toDouble();
        if (radius > 0) {
          canvas.drawRRect(RRect.fromRectXY(rect, radius, radius), paint);
        } else {
          canvas.drawRect(rect, paint);
        }
        break;
      case 'circle':
        canvas.drawCircle(
          Offset((shape['centerX'] as num).toDouble(),
              (shape['centerY'] as num).toDouble()),
          (shape['radius'] as num).toDouble(),
          paint,
        );
        break;
      case 'line':
        canvas.drawLine(
          Offset(
              (shape['x1'] as num).toDouble(), (shape['y1'] as num).toDouble()),
          Offset(
              (shape['x2'] as num).toDouble(), (shape['y2'] as num).toDouble()),
          paint,
        );
        break;
      case 'path':
        final path = Path();
        path.fillType = PathFillType.values[shape['fillType'] as int];
        for (final cmd in (shape['commands'] as List)) {
          final commandMap = cmd as Map<String, dynamic>;
          switch (commandMap['command']) {
            case 'moveTo':
              path.moveTo(
                  (cmd['x'] as num).toDouble(), (cmd['y'] as num).toDouble());
              break;
            case 'lineTo':
              path.lineTo(
                  (cmd['x'] as num).toDouble(), (cmd['y'] as num).toDouble());
              break;
            case 'close':
              path.close();
              break;
          }
        }
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant NexusPainter oldDelegate) {
    // Deep equality check on the render packet.
    return !const DeepCollectionEquality()
        .equals(oldDelegate.renderPacket, renderPacket);
  }

  @override
  bool? hitTest(Offset position) {
    // Iterate backwards for correct z-index hit testing.
    for (final command in renderPacket.reversed) {
      if (command['interactive'] == null) {
        continue;
      }

      final transform = command['transform'] as Map<String, dynamic>;
      final tx = (transform['x'] as num).toDouble();
      final ty = (transform['y'] as num).toDouble();
      final scale = (transform['scale'] as num).toDouble();

      // Inverse transform the hit position
      final localPosition = Offset(
        (position.dx - tx) / scale,
        (position.dy - ty) / scale,
      );

      final shape = command['shape'] as Map<String, dynamic>;
      bool isHit = false;

      switch (shape['type']) {
        case 'rectangle':
          final rect = Rect.fromLTWH(
            (shape['x'] as num).toDouble(),
            (shape['y'] as num).toDouble(),
            (shape['width'] as num).toDouble(),
            (shape['height'] as num).toDouble(),
          );
          if (rect.contains(localPosition)) {
            isHit = true;
          }
          break;
        case 'circle':
          final center = Offset((shape['centerX'] as num).toDouble(),
              (shape['centerY'] as num).toDouble());
          final radius = (shape['radius'] as num).toDouble();
          if ((localPosition - center).distanceSquared < radius * radius) {
            isHit = true;
          }
          break;
        // Add hit-testing for other shapes (path, etc.)
      }

      if (isHit) {
        final interactive = command['interactive'] as Map<String, dynamic>;
        if (interactive['onTap'] == true) {
          final entityId = command['entityId'] as int;
          // Send an event back to the logic isolate.
          renderingSystem.manager?.send(EntityTapEvent(entityId));
        }
        // If we hit a shape, we stop and don't check shapes below it.
        return true;
      }
    }

    // No hit on any interactive shape.
    return false;
  }
}
