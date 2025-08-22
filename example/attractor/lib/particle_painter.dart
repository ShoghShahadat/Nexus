import 'package:flutter/material.dart';
import 'components/particle_render_data_component.dart';

/// A custom painter to efficiently render all game entities in the multiplayer world.
class ParticlePainter extends CustomPainter {
  // This painter is now simplified, as most logic is driven by server data.
  // We just need to know where all the different types of entities are.
  final List<Offset> meteorPositions;
  final List<Offset> healthOrbPositions;
  final List<Offset> allPlayerPositions;
  final Offset? localPlayerPosition;

  ParticlePainter({
    required this.meteorPositions,
    required this.healthOrbPositions,
    required this.allPlayerPositions,
    this.localPlayerPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // --- Other Player Rendering ---
    final otherPlayerPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.8);
    for (final pos in allPlayerPositions) {
      // Don't draw the local player in this loop
      if (pos == localPlayerPosition) continue;
      canvas.drawCircle(
        pos,
        10,
        otherPlayerPaint,
      );
    }

    // --- Local Player Rendering (highlighted) ---
    if (localPlayerPosition != null) {
      final localPlayerPaint = Paint()..color = Colors.yellowAccent;
      final localPlayerGlow = Paint()
        ..color = Colors.yellowAccent.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(localPlayerPosition!, 12, localPlayerGlow);
      canvas.drawCircle(
        localPlayerPosition!,
        10,
        localPlayerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    // For simplicity, always repaint. Can be optimized later if needed.
    return true;
  }
}
