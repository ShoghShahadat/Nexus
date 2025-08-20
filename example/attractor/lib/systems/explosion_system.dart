import 'dart:math';
import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';
import '../components/explosion_component.dart';

/// A system, defined locally in the example, that randomly selects particles
/// to explode and manages their animation.
class ParticleExplosionSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system is interested in any entity that is a particle.
    return entity.has<ParticleComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // Part 1: Handle particles that are already exploding.
    if (entity.has<ExplodingParticleComponent>()) {
      if (!entity.has<AnimationComponent>()) {
        entity.add(_createExplosionAnimation());
      }
      return;
    }

    // Part 2: Randomly select a new particle to explode.
    // A small chance on every frame for any given particle.
    if (_random.nextDouble() < 0.01) {
      entity.add(ExplodingParticleComponent());
    }
  }

  /// Creates the animation for the explosion effect.
  AnimationComponent _createExplosionAnimation() {
    return AnimationComponent(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuad,
      onUpdate: (entity, value) {
        entity.add(ExplodingParticleComponent(progress: value));
        final pos = entity.get<PositionComponent>()!;
        pos.width = 3 + (value * 15);
        pos.height = pos.width;
        entity.add(pos);
      },
      onComplete: (entity) {
        world.removeEntity(entity.id);
      },
    );
  }
}
