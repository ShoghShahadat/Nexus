// ==============================================================================
// File: lib/systems/attractor_system.dart
// Author: Your Intelligent Assistant
// Version: 2.0
// Description: A pure Dart, CPU-based system to simulate and manage particle attraction.
// Changes:
// - CRITICAL FIX: The entire file has been replaced with the full, original
//   gameplay logic from the initial version. This restores the particle
//   simulation, attraction physics, particle lifecycle (aging/respawning),
//   and rendering data generation, fixing the missing particle effect.
// ==============================================================================

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import '../components/attractor_component.dart' hide AttractorComponent;
import '../components/network_components.dart';
import '../components/particle_render_data_component.dart';

// Internal data structure for particle simulation state. Not an entity/component.
class ParticleData {
  double x, y;
  double velX, velY;
  double age;
  final double maxAge;
  final double initialSize;

  ParticleData({
    required this.x,
    required this.y,
    required this.velX,
    required this.velY,
    this.age = 0.0,
    required this.maxAge,
    required this.initialSize,
  });
}

class AttractorSystem extends System {
  final int particleCount;
  final Random _random = Random();
  late List<ParticleData> _particles;

  AttractorSystem({this.particleCount = 500});

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _initializeParticles();
  }

  void _initializeParticles() {
    _particles = List.generate(particleCount, (i) {
      final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
      final w = screenInfo?.width ?? 800;
      final h = screenInfo?.height ?? 600;
      return _createParticle(w / 2, h * 0.8);
    });
  }

  ParticleData _createParticle(double x, double y) {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 150 + 50;
    return ParticleData(
      x: x,
      y: y,
      velX: cos(angle) * speed,
      velY: sin(angle) * speed,
      age: 0.0,
      maxAge: _random.nextDouble() * 3 + 2,
      initialSize: _random.nextDouble() * 2.0 + 1.0,
    );
  }

  @override
  bool matches(Entity entity) {
    // This system runs its logic once per frame, tied to the root entity.
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final attractorEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());
    if (attractorEntity == null) return;

    final attractorPos = attractorEntity.get<PositionComponent>()!;
    final attractorComp = attractorEntity.get<AttractorComponent>()!;
    final health = attractorEntity.get<HealthComponent>();
    final isGameOver = (health?.currentHealth ?? 1) <= 0;

    if (isGameOver) {
      entity.add(ParticleRenderDataComponent([]));
      return;
    }

    // Update all particles
    for (final p in _particles) {
      // Attraction logic
      final dirX = attractorPos.x - p.x;
      final dirY = attractorPos.y - p.y;
      final distSq = (dirX * dirX) + (dirY * dirY);

      if (distSq > 1.0) {
        final dist = sqrt(distSq);
        final force = attractorComp.strength * 1000.0 / distSq;
        p.velX += (dirX / dist) * force * dt;
        p.velY += (dirY / dist) * force * dt;
      }

      // Movement
      p.x += p.velX * dt;
      p.y += p.velY * dt;
      p.age += dt;

      // Respawn logic
      if (p.age >= p.maxAge) {
        final newParticle = _createParticle(attractorPos.x, attractorPos.y);
        p.x = newParticle.x;
        p.y = newParticle.y;
        p.velX = newParticle.velX;
        p.velY = newParticle.velY;
        p.age = 0.0;
      }
    }

    // Create renderable data
    final renderableParticles = _particles.map((p) {
      final progress = (p.age / p.maxAge).clamp(0.0, 1.0);
      final radius = p.initialSize * (1.0 - progress);
      final alpha = (255 * (1.0 - progress)).round();
      return RenderableParticle(
        x: p.x,
        y: p.y,
        radius: radius,
        colorValue: Colors.white.withAlpha(alpha).value,
      );
    }).toList();

    // Add the component with render data to the root entity
    entity.add(ParticleRenderDataComponent(renderableParticles));
  }
}
