import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';

/// A system, defined locally, that handles the burning, shrinking, and particle
/// shedding of meteors.
class MeteorBurnSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    return entity.has<MeteorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final meteor = entity.get<MeteorComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    // Decrease health over time.
    meteor.health -= dt * 0.3; // Meteor lasts for about 3.3 seconds

    if (meteor.health <= 0) {
      // Explode into a final burst of particles and then disappear.
      for (int i = 0; i < 20; i++) {
        _createDebrisParticle(pos);
      }
      world.removeEntity(entity.id);
      return;
    }

    // Shrink the meteor as it burns.
    pos.width = 25 * meteor.health;
    pos.height = 25 * meteor.health;

    // Periodically shed debris particles.
    if (_random.nextDouble() < 0.5) {
      _createDebrisParticle(pos);
    }

    entity.add(meteor);
    entity.add(pos);
  }

  void _createDebrisParticle(PositionComponent meteorPos) {
    final debris = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 40 + 10; // Debris is slow

    debris.add(PositionComponent(
      x: meteorPos.x + (_random.nextDouble() - 0.5) * meteorPos.width,
      y: meteorPos.y + (_random.nextDouble() - 0.5) * meteorPos.width,
      width: 2,
      height: 2,
    ));
    debris.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    // Debris particles are just normal particles.
    debris.add(ParticleComponent(
      maxAge: _random.nextDouble() * 1.5 + 0.5, // Debris lasts 0.5-2s
      initialColorValue: 0xFFFFE082, // Yellowish
      finalColorValue: 0xFF757575, // Fades to grey
    ));
    debris.add(TagsComponent({'particle'}));
    world.addEntity(debris);
  }
}
