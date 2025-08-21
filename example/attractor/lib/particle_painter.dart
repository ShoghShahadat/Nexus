import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// A custom painter to efficiently render a large number of particles from raw GPU data,
/// along with other game entities like the attractor, meteors, and health orbs.
class ParticlePainter extends CustomPainter {
  final Float32List? gpuParticleData;
  final List<EntityId> meteorIds;
  final EntityId attractorId;
  final List<EntityId> healthOrbIds;
  final FlutterRenderingSystem controller;

  ParticlePainter({
    required this.gpuParticleData,
    required this.meteorIds,
    required this.attractorId,
    required this.healthOrbIds,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint();
    final attractorPaint = Paint()..color = Colors.yellowAccent;
    final meteorPaint = Paint();
    final healthOrbPaint = Paint()..color = Colors.greenAccent.shade400;
    final healthBarBgPaint = Paint()..color = Colors.grey.shade800;
    final healthBarFgPaint = Paint()..color = Colors.green;

    if (gpuParticleData != null) {
      final data = gpuParticleData!;
      // Data layout is now [x, y, size, opacity_or_negative_color]
      for (int i = 0; i < data.length; i += 4) {
        final x = data[i];
        final y = data[i + 1];
        final radius = data[i + 2];
        final fourthValue = data[i + 3];

        if (radius > 0.1) {
          // FIX: Use a robust check. Positive values are opacity for white particles.
          // Negative values are the color for exploding particles.
          if (fourthValue >= 0) {
            // It's a normal particle, fourthValue is opacity.
            particlePaint.color = Colors.white.withOpacity(fourthValue);
          } else {
            // It's an exploding particle, fourthValue is the negative color.
            particlePaint.color = Color((-fourthValue).toInt());
          }
          canvas.drawCircle(Offset(x, y), radius, particlePaint);
        }
      }
    }

    // --- The rest of the drawing logic remains the same ---

    // Draw all the meteors
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

    // Draw all the health orbs
    for (final id in healthOrbIds) {
      final pos = controller.get<PositionComponent>(id);
      final health = controller.get<HealthComponent>(id);
      if (pos == null || health == null) continue;

      canvas.drawCircle(Offset(pos.x, pos.y), pos.width / 2, healthOrbPaint);

      final healthRatio =
          (health.currentHealth / health.maxHealth).clamp(0.0, 1.0);
      const barWidth = 20.0;
      const barHeight = 4.0;
      final barX = pos.x - barWidth / 2;
      final barY = pos.y - (pos.width / 2) - 8;

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight),
            const Radius.circular(2)),
        healthBarBgPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barWidth * healthRatio, barHeight),
            const Radius.circular(2)),
        healthBarFgPaint,
      );
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
