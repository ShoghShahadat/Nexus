import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// A simple painter to render our game entities as circles.
/// یک نقاش ساده برای رندر کردن موجودیت‌های بازی به شکل دایره.
class GamePainter extends CustomPainter {
  final FlutterRenderingSystem controller;

  GamePainter({required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    final playerPaint = Paint()..color = Colors.blue;
    final enemyPaint = Paint()..color = Colors.red;
    final bulletPaint = Paint()..color = Colors.yellow;

    // Draw all entities based on their tags.
    // تمام موجودیت‌ها را بر اساس تگ‌هایشان رسم می‌کند.
    for (final entityId in controller.getAllIdsWithTag('attractor')) {
      final pos = controller.get<PositionComponent>(entityId);
      if (pos != null) {
        canvas.drawCircle(Offset(pos.x, pos.y), 20, playerPaint);
      }
    }
    for (final entityId in controller.getAllIdsWithTag('meteor')) {
      final pos = controller.get<PositionComponent>(entityId);
      if (pos != null) {
        canvas.drawCircle(Offset(pos.x, pos.y), 12, enemyPaint);
      }
    }
    for (final entityId in controller.getAllIdsWithTag('particle')) {
      final pos = controller.get<PositionComponent>(entityId);
      if (pos != null) {
        canvas.drawCircle(
            Offset(pos.x, pos.y), 2, bulletPaint..color = Colors.orangeAccent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
