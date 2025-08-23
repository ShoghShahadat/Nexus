// ==============================================================================
// File: lib/particle_painter.dart
// Author: Your Intelligent Assistant
// Version: 7.0
// Description: A custom painter to efficiently render all game entities.
// Changes:
// - CODE COMPLETION: The `_drawEntities` method has been fully implemented
//   to render players and health orbs correctly relative to the camera offset,
//   restoring their visibility in the game.
// ==============================================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'components/particle_render_data_component.dart';

class ParticlePainter extends CustomPainter {
  final List<RenderableParticle> particles;
  final List<EntityId> allPlayerIds;
  final List<EntityId> meteorIds;
  final List<EntityId> healthOrbIds;
  final EntityId? localPlayerId;
  final FlutterRenderingSystem controller;

  static const int _starCount = 200;
  static const double _worldWidth = 2000;
  static const double _worldHeight = 2000;
  final List<Offset> _stars;
  final Paint _starPaint = Paint()..color = Colors.white.withAlpha(180);
  static double _cameraX = 0;
  static double _cameraY = 0;
  static bool _cameraInitialized = false;

  ParticlePainter({
    required this.particles,
    required this.allPlayerIds,
    required this.meteorIds,
    required this.healthOrbIds,
    required this.controller,
    this.localPlayerId,
  }) : _stars = List.generate(
          _starCount,
          (index) => Offset(
            Random().nextDouble() * _worldWidth,
            Random().nextDouble() * _worldHeight,
          ),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final localPlayerPos = localPlayerId != null
        ? controller.get<PositionComponent>(localPlayerId!)
        : null;

    if (localPlayerPos != null) {
      if (!_cameraInitialized) {
        _cameraX = localPlayerPos.x;
        _cameraY = localPlayerPos.y;
        _cameraInitialized = true;
      }
      const lerpFactor = 0.05;
      _cameraX += (localPlayerPos.x - _cameraX) * lerpFactor;
      _cameraY += (localPlayerPos.y - _cameraY) * lerpFactor;
    }

    final double offsetX = _cameraX - size.width / 2;
    final double offsetY = _cameraY - size.height / 2;

    // Draw Starfield
    for (final star in _stars) {
      final screenX = star.dx - offsetX;
      final screenY = star.dy - offsetY;
      final wrappedX = (screenX + _worldWidth) % _worldWidth;
      final wrappedY = (screenY + _worldHeight) % _worldHeight;
      if (wrappedX >= 0 &&
          wrappedX <= size.width &&
          wrappedY >= 0 &&
          wrappedY <= size.height) {
        canvas.drawCircle(Offset(wrappedX, wrappedY), 1.0, _starPaint);
      }
    }

    // Particle Rendering (Screen Space)
    final particlePaint = Paint();
    for (final p in particles) {
      if (p.radius > 0.1) {
        particlePaint.color = Color(p.colorValue);
        canvas.drawCircle(Offset(p.x, p.y), p.radius, particlePaint);
      }
    }

    // Render other entities relative to the camera
    _drawEntities(canvas, offsetX, offsetY);
  }

  void _drawEntities(Canvas canvas, double offsetX, double offsetY) {
    // Meteor Rendering
    final meteorPaint = Paint();
    for (final id in meteorIds) {
      final pos = controller.get<PositionComponent>(id);
      if (pos == null) continue;
      final screenOffset = Offset(pos.x - offsetX, pos.y - offsetY);
      final rect = Rect.fromCircle(center: screenOffset, radius: pos.width / 2);
      meteorPaint.shader = const RadialGradient(
        colors: [Colors.white, Colors.orangeAccent, Colors.transparent],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);
      canvas.drawCircle(screenOffset, pos.width / 2, meteorPaint);
    }

    // Health Orb Rendering
    final healthOrbPaint = Paint()..color = Colors.greenAccent.shade400;
    final healthOrbArcPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final id in healthOrbIds) {
      final pos = controller.get<PositionComponent>(id);
      final health = controller.get<HealthComponent>(id);
      if (pos == null || health == null) continue;
      final screenOffset = Offset(pos.x - offsetX, pos.y - offsetY);
      canvas.drawCircle(screenOffset, 6, healthOrbPaint);
      final healthRatio =
          (health.currentHealth / health.maxHealth).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: screenOffset, radius: 9),
        -pi / 2,
        2 * pi * healthRatio,
        false,
        healthOrbArcPaint,
      );
    }

    // Player Rendering
    final otherPlayerPaint = Paint()
      ..color = Colors.lightBlueAccent.withAlpha(204);
    final localPlayerPaint = Paint()..color = Colors.yellowAccent;
    final localPlayerGlow = Paint()
      ..color = Colors.yellowAccent.withAlpha(77)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    final healthBarBackgroundPaint = Paint()..color = Colors.red.shade900;
    final healthBarForegroundPaint = Paint()
      ..color = Colors.greenAccent.shade400;

    for (final id in allPlayerIds) {
      final pos = controller.get<PositionComponent>(id);
      final health = controller.get<HealthComponent>(id);
      if (pos == null) continue;
      final screenOffset = Offset(pos.x - offsetX, pos.y - offsetY);
      final isLocal = id == localPlayerId;
      final radius = pos.width / 2;

      if (isLocal) {
        canvas.drawCircle(screenOffset, radius * 1.2, localPlayerGlow);
        canvas.drawCircle(screenOffset, radius, localPlayerPaint);
      } else {
        canvas.drawCircle(screenOffset, radius, otherPlayerPaint);
      }

      if (health != null) {
        final healthRatio =
            (health.currentHealth / health.maxHealth).clamp(0.0, 1.0);
        const barWidth = 30.0;
        const barHeight = 5.0;
        final barOffset = Offset(
            screenOffset.dx - barWidth / 2, screenOffset.dy - (radius + 15));
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
