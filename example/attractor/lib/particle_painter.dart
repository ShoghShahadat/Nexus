import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// A custom painter to efficiently render all game entities.
class ParticlePainter extends CustomPainter {
  final List<EntityId> allPlayerIds;
  final List<EntityId> meteorIds;
  final List<EntityId> healthOrbIds;
  final EntityId? localPlayerId;
  final FlutterRenderingSystem controller;

  ParticlePainter({
    required this.allPlayerIds,
    required this.meteorIds,
    required this.healthOrbIds,
    required this.controller,
    this.localPlayerId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Meteor Rendering ---
    final meteorPaint = Paint();
    for (final id in meteorIds) {
      final pos = controller.get<PositionComponent>(id);
      if (pos == null) continue;

      final radius = pos.width / 2;
      final offset = Offset(pos.x, pos.y);
      final rect = Rect.fromCircle(center: offset, radius: radius);
      meteorPaint.shader = const RadialGradient(
        colors: [Colors.white, Colors.orangeAccent, Colors.transparent],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);
      canvas.drawCircle(offset, radius, meteorPaint);
    }

    // --- Health Orb Rendering with Lifetime Indicator ---
    final healthOrbPaint = Paint()..color = Colors.greenAccent.shade400;
    final healthOrbArcPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final id in healthOrbIds) {
      final pos = controller.get<PositionComponent>(id);
      final health = controller.get<HealthComponent>(id);
      if (pos == null || health == null) continue;

      final offset = Offset(pos.x, pos.y);
      canvas.drawCircle(offset, 6, healthOrbPaint);

      final healthRatio =
          (health.currentHealth / health.maxHealth).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: offset, radius: 9),
        -pi / 2,
        2 * pi * healthRatio,
        false,
        healthOrbArcPaint,
      );
    }

    // --- Player Rendering with Health Bars ---
    final otherPlayerPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.8);
    final localPlayerPaint = Paint()..color = Colors.yellowAccent;
    final localPlayerGlow = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    final healthBarBackgroundPaint = Paint()..color = Colors.red.shade900;
    final healthBarForegroundPaint = Paint()
      ..color = Colors.greenAccent.shade400;

    for (final id in allPlayerIds) {
      final pos = controller.get<PositionComponent>(id);
      final health = controller.get<HealthComponent>(id);
      if (pos == null) continue;

      final offset = Offset(pos.x, pos.y);
      final isLocal = id == localPlayerId;
      // --- FIX: Use size from PositionComponent instead of hardcoded values ---
      final radius = pos.width / 2;

      // Draw player body
      if (isLocal) {
        canvas.drawCircle(
            offset, radius * 1.2, localPlayerGlow); // Glow is slightly larger
        canvas.drawCircle(offset, radius, localPlayerPaint);
      } else {
        canvas.drawCircle(offset, radius, otherPlayerPaint);
      }

      // Draw health bar above the player
      if (health != null) {
        final healthRatio =
            (health.currentHealth / health.maxHealth).clamp(0.0, 1.0);
        const barWidth = 30.0;
        const barHeight = 5.0;
        final barOffset =
            Offset(offset.dx - barWidth / 2, offset.dy - (radius + 15));

        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(barOffset.dx, barOffset.dy, barWidth, barHeight),
                const Radius.circular(2)),
            healthBarBackgroundPaint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(barOffset.dx, barOffset.dy,
                    barWidth * healthRatio, barHeight),
                const Radius.circular(2)),
            healthBarForegroundPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true;
  }
}
