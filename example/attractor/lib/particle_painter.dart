import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import './components/explosion_component.dart';

/// A custom painter to efficiently render a large number of particles,
/// the attractor, meteors, and now, health orbs.
class ParticlePainter extends CustomPainter {
  final List<EntityId> particleIds;
  final List<EntityId> meteorIds;
  final EntityId attractorId;
  // --- NEW: Add health orb IDs to the painter ---
  final List<EntityId> healthOrbIds;
  final FlutterRenderingSystem controller;

  ParticlePainter({
    required this.particleIds,
    required this.meteorIds,
    required this.attractorId,
    // --- NEW: Receive health orb IDs ---
    required this.healthOrbIds,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint();
    final attractorPaint = Paint()..color = Colors.yellowAccent;
    final meteorPaint = Paint();
    // --- NEW: Paints for health orbs and their health bars ---
    final healthOrbPaint = Paint()..color = Colors.greenAccent.shade400;
    final healthBarBgPaint = Paint()..color = Colors.grey.shade800;
    final healthBarFgPaint = Paint()..color = Colors.green;

    // Draw all the meteors with a fiery gradient
    for (final id in meteorIds) {
      final pos = controller.get<PositionComponent>(id);
      if (pos == null) continue;

      final rect =
          Rect.fromCircle(center: Offset(pos.x, pos.y), radius: pos.width / 2);
      meteorPaint.shader = const RadialGradient(
        colors: [Colors.white, Colors.orangeAccent, Colors.transparent],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);

      canvas.drawCircle(Offset(pos.x, pos.y), pos.width / 2, meteorPaint);
    }

    // --- NEW: Draw all the health orbs ---
    for (final id in healthOrbIds) {
      final pos = controller.get<PositionComponent>(id);
      final health = controller.get<HealthComponent>(id);
      if (pos == null || health == null) continue;

      // Draw the orb itself
      canvas.drawCircle(Offset(pos.x, pos.y), pos.width / 2, healthOrbPaint);

      // Draw the health bar above the orb
      final healthRatio =
          (health.currentHealth / health.maxHealth).clamp(0.0, 1.0);
      const barWidth = 20.0;
      const barHeight = 4.0;
      final barX = pos.x - barWidth / 2;
      final barY = pos.y - (pos.width / 2) - 8; // 8 pixels above the orb

      // Background of the bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight),
            const Radius.circular(2)),
        healthBarBgPaint,
      );
      // Foreground (actual health)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barWidth * healthRatio, barHeight),
            const Radius.circular(2)),
        healthBarFgPaint,
      );
    }

    // Draw all the particles
    for (final id in particleIds) {
      final pos = controller.get<PositionComponent>(id);
      final particle = controller.get<ParticleComponent>(id);
      final exploding = controller.get<ExplodingParticleComponent>(id);

      if (pos == null || particle == null) continue;

      if (exploding != null) {
        final explosionProgress = exploding.progress;
        particlePaint.color =
            Colors.redAccent.withOpacity(1.0 - explosionProgress);
        canvas.drawCircle(Offset(pos.x, pos.y), pos.width / 2, particlePaint);
      } else {
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
