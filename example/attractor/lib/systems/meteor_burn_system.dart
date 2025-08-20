import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/components/meteor_component.dart';

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

    meteor.health -= dt * 0.3;

    if (meteor.health <= 0) {
      // --- NEW: Award points when a meteor burns up ---
      // --- جدید: اهدای امتیاز هنگام سوختن کامل شهاب‌سنگ ---
      final rootEntity = world.entities.values.firstWhereOrNull(
          (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
      if (rootEntity != null) {
        final blackboard = rootEntity.get<BlackboardComponent>()!;
        blackboard.increment('score', 5); // 5 points for a burn-up
        rootEntity.add(blackboard);
      }

      for (int i = 0; i < 20; i++) {
        _createDebrisParticle(pos);
      }
      world.removeEntity(entity.id);
      return;
    }

    pos.width = 25 * meteor.health;
    pos.height = 25 * meteor.health;

    if (_random.nextDouble() < 0.5) {
      _createDebrisParticle(pos);
    }

    entity.add(meteor);
    entity.add(pos);
  }

  void _createDebrisParticle(PositionComponent meteorPos) {
    final debris = Entity();
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 40 + 10;

    debris.add(PositionComponent(
      x: meteorPos.x + (_random.nextDouble() - 0.5) * meteorPos.width,
      y: meteorPos.y + (_random.nextDouble() - 0.5) * meteorPos.width,
      width: 2,
      height: 2,
    ));
    debris.add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
    debris.add(ParticleComponent(
      maxAge: _random.nextDouble() * 1.5 + 0.5,
      initialColorValue: 0xFFFFE082,
      finalColorValue: 0xFF757575,
    ));
    debris.add(TagsComponent({'particle'}));
    world.addEntity(debris);
  }
}
