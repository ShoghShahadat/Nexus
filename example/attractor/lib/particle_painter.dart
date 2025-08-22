import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

/// A custom painter to efficiently render a large number of particles from raw GPU data,
/// along with other game entities like the attractor, meteors, and health orbs.
class ParticlePainter extends CustomPainter {
  final Float32List? gpuParticleData;
  final List<Offset> meteorPositions;
  final Offset? attractorPosition;
  final List<Offset> healthOrbPositions;

  ParticlePainter({
    required this.gpuParticleData,
    required this.meteorPositions,
    required this.attractorPosition,
    required this.healthOrbPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Particle Rendering (Corrected) ---
    final particlePaint = Paint();
    if (gpuParticleData != null) {
      final data = gpuParticleData!;
      // This loop is highly optimized for drawing particles from raw data.
      for (int i = 0; i < data.length; i += 4) {
        final x = data[i];
        final y = data[i + 1];
        final radius = data[i + 2];
        final fourthValue = data[i + 3];

        if (radius > 0.1) {
          if (fourthValue >= 0) {
            // Use a simple white color with varying opacity.
            particlePaint.color = Color.fromRGBO(255, 255, 255, fourthValue);
          } else {
            // Use the negative value as the full ARGB color for explosions.
            particlePaint.color = Color((-fourthValue).toInt());
          }
          canvas.drawCircle(Offset(x, y), radius, particlePaint);
        }
      }
    }

    // --- Meteor Rendering (VISUALS RESTORED) ---
    // We go back to drawing circles in a loop to restore the correct visuals.
    // This is still fast because we are iterating over a simple List<Offset>
    // and not performing expensive lookups inside the paint method.
    // به رسم دایره در یک حلقه بازمی‌گردیم تا ظاهر صحیح را بازیابی کنیم.
    // این روش همچنان سریع است زیرا روی یک `List<Offset>` ساده پیمایش می‌کنیم
    // و جستجوهای هزینه‌بر را درون متد paint انجام نمی‌دهیم.
    final meteorPaint = Paint();
    for (final pos in meteorPositions) {
      final rect = Rect.fromCircle(center: pos, radius: 12);
      // Restore the beautiful gradient shader for meteors
      meteorPaint.shader = const RadialGradient(
        colors: [Colors.white, Colors.orangeAccent, Colors.transparent],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);
      canvas.drawCircle(pos, 12, meteorPaint);
    }

    // --- Health Orb Rendering (VISUALS RESTORED) ---
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
    // We can add more granular checks here later if needed, but for now,
    // always repainting is fine.
    return true;
  }
}
