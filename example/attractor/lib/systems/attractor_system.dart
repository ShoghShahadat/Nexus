import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import '../components/attractor_component.dart' hide AttractorComponent;
import '../components/particle_render_data_component.dart';

class AttractorSystem extends System {
  final int particleCount;
  final Random _random = Random();
  late List<RenderableParticle> _particles;

  AttractorSystem({this.particleCount = 500});

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _initializeParticles();
  }

  void _initializeParticles() {
    final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
    final w = screenInfo?.width ?? 800;
    final h = screenInfo?.height ?? 600;
    _particles =
        List.generate(particleCount, (i) => _createParticle(w / 2, h * 0.8));
  }

  RenderableParticle _createParticle(double x, double y) {
    return RenderableParticle(
        x: x, y: y, radius: _random.nextDouble() * 2.0 + 1.0, colorValue: 0);
  }

  @override
  bool matches(Entity entity) {
    return entity.has<AttractorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final attractorPos = entity.get<PositionComponent>()!;
    final attractorComp = entity.get<AttractorComponent>()!;
    final screenInfo = world.rootEntity.get<ScreenInfoComponent>()!;

    // This is a simplified particle simulation that runs on the CPU
    // In a real game, this would be a perfect candidate for a GPU compute shader
    for (var i = 0; i < _particles.length; i++) {
      var p = _particles[i];
      // Attraction logic would go here, for now, they just exist
    }

    // This system now directly generates the renderable data
    world.rootEntity.add(ParticleRenderDataComponent(_particles));
  }
}
