import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// A custom painter to efficiently render a large number of particles.
class ParticlePainter extends CustomPainter {
  final List<EntityId> particleIds;
  final FlutterRenderingSystem controller;

  ParticlePainter({required this.particleIds, required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final id in particleIds) {
      final pos = controller.get<PositionComponent>(id);
      final particle = controller.get<ParticleComponent>(id);

      if (pos == null || particle == null) continue;

      final progress = (particle.age / particle.maxAge).clamp(0.0, 1.0);
      final color = Color.lerp(Color(particle.initialColorValue),
          Color(particle.finalColorValue), progress)!;

      // Fade in and out
      final opacity = progress < 0.1
          ? progress / 0.1
          : (progress > 0.9 ? (1.0 - progress) / 0.1 : 1.0);

      paint.color = color.withOpacity(opacity);

      final radius = pos.width * (1 - progress);

      canvas.drawCircle(Offset(pos.x, pos.y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
