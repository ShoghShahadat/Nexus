import 'dart:math';
import 'package:flutter/material.dart';

/// A customizable virtual joystick widget for Flutter.
class Joystick extends StatefulWidget {
  /// Called when the joystick's position changes.
  /// The Offset value is normalized between -1.0 and 1.0.
  final ValueChanged<Offset> onChanged;

  const Joystick({super.key, required this.onChanged});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _offset = Offset.zero;
  final double _baseRadius = 60.0;
  final double _knobRadius = 25.0;

  void _onPanStart(DragStartDetails details) {
    _updatePosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updatePosition(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    // Reset to center when the user lifts their finger.
    _updatePosition(Offset(_baseRadius, _baseRadius));
  }

  void _updatePosition(Offset localPosition) {
    // Calculate the vector from the center of the joystick base.
    final center = Offset(_baseRadius, _baseRadius);
    var vector = localPosition - center;

    // Clamp the vector's magnitude to the base radius.
    final distance = vector.distance;
    if (distance > _baseRadius) {
      vector = vector / distance * _baseRadius;
    }

    setState(() {
      _offset = vector;
    });

    // Notify the parent widget with the normalized vector.
    widget.onChanged(Offset(
      (vector.dx / _baseRadius).clamp(-1.0, 1.0),
      (vector.dy / _baseRadius).clamp(-1.0, 1.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _baseRadius * 2,
      height: _baseRadius * 2,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _JoystickPainter(
            baseRadius: _baseRadius,
            knobRadius: _knobRadius,
            knobOffset: _offset,
          ),
        ),
      ),
    );
  }
}

/// A custom painter for rendering the joystick's visual appearance.
class _JoystickPainter extends CustomPainter {
  final double baseRadius;
  final double knobRadius;
  final Offset knobOffset;

  _JoystickPainter({
    required this.baseRadius,
    required this.knobRadius,
    required this.knobOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Paint for the joystick base
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final baseBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Paint for the joystick knob
    final knobPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
      ).createShader(
          Rect.fromCircle(center: center + knobOffset, radius: knobRadius))
      ..style = PaintingStyle.fill;

    // Draw the base
    canvas.drawCircle(center, baseRadius, basePaint);
    canvas.drawCircle(center, baseRadius, baseBorderPaint);

    // Draw the knob
    canvas.drawCircle(center + knobOffset, knobRadius, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return oldDelegate.knobOffset != knobOffset;
  }
}
