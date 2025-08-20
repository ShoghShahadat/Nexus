import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import './components/explosion_component.dart'; // Import the local component

/// A custom painter to efficiently render a large number of particles and the attractor.
class ParticlePainter extends CustomPainter {
  final List<EntityId> particleIds;
  final EntityId attractorId;
  final FlutterRenderingSystem controller;

  ParticlePainter({
    required this.particleIds,
    required this.attractorId,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint();
    final attractorPaint = Paint()..color = Colors.yellowAccent;

    // Draw all the particles
    for (final id in particleIds) {
      final pos = controller.get<PositionComponent>(id);
      final particle = controller.get<ParticleComponent>(id);
      final exploding = controller.get<ExplodingParticleComponent>(id);

      if (pos == null || particle == null) continue;

      // --- NEW: Handle rendering for exploding particles ---
      if (exploding != null) {
        final explosionProgress = exploding.progress;
        // The particle becomes red and fades out as it explodes.
        particlePaint.color =
            Colors.redAccent.withOpacity(1.0 - explosionProgress);
        canvas.drawCircle(Offset(pos.x, pos.y), pos.width / 2, particlePaint);
      } else {
        // --- Original rendering for normal particles ---
        final progress = (particle.age / particle.maxAge).clamp(0.0, 1.0);
        final color = Color.lerp(Color(particle.initialColorValue),
            Color(particle.finalColorValue), progress)!;

        final opacity = progress < 0.1
            ? progress / 0.1
            : (progress > 0.9 ? (1.0 - progress) / 0.1 : 1.0);

        particlePaint.color = color.withOpacity(opacity);

        final radius = pos.width * (1 - progress);

        canvas.drawCircle(Offset(pos.x, pos.y), radius, particlePaint);
      }
    }

    // Draw the attractor
    final attractorPos = controller.get<PositionComponent>(attractorId);
    if (attractorPos != null) {
      canvas.drawCircle(
        Offset(attractorPos.x, attractorPos.y),
        attractorPos.width / 2,
        attractorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
