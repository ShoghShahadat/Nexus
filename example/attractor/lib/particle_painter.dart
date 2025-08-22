import 'package:flutter/material.dart';
import 'components/particle_render_data_component.dart';

/// A custom painter to efficiently render game entities, including CPU-calculated particles.
class ParticlePainter extends CustomPainter {
  final List<RenderableParticle> particles;
  final List<Offset> meteorPositions;
  final Offset? attractorPosition;
  final List<Offset> healthOrbPositions;

  ParticlePainter({
    required this.particles,
    required this.meteorPositions,
    required this.attractorPosition,
    required this.healthOrbPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Particle Rendering (from CPU data) ---
    final particlePaint = Paint();
    for (final p in particles) {
      if (p.radius > 0.1) {
        particlePaint.color = Color(p.colorValue);
        canvas.drawCircle(Offset(p.x, p.y), p.radius, particlePaint);
      }
    }

    // --- Meteor Rendering ---
    final meteorPaint = Paint();
    for (final pos in meteorPositions) {
      final rect = Rect.fromCircle(center: pos, radius: 12);
      meteorPaint.shader = const RadialGradient(
        colors: [Colors.white, Colors.orangeAccent, Colors.transparent],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);
      canvas.drawCircle(pos, 12, meteorPaint);
    }

    // --- Health Orb Rendering ---
    final healthOrbPaint = Paint()..color = Colors.greenAccent.shade400;
    for (final pos in healthOrbPositions) {
      canvas.drawCircle(pos, 6, healthOrbPaint);
    }

    // --- Attractor Rendering ---
    if (attractorPosition != null) {
      final attractorPaint = Paint()..color = Colors.yellowAccent;
      canvas.drawCircle(
        attractorPosition!,
        10,
        attractorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    // For simplicity, always repaint. Can be optimized later if needed.
    return true;
  }
}
