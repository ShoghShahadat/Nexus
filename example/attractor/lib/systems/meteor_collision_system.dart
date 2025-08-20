import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/meteor_target_component.dart';

/// A system that checks for collisions between homing meteors and their targets.
class MeteorCollisionSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    final target = entity.get<MeteorTargetComponent>();
    return entity.has<MeteorComponent>() &&
        target != null &&
        target.targetId != null;
  }

  @override
  void update(Entity entity, double dt) {
    final meteorPos = entity.get<PositionComponent>()!;
    final targetId = entity.get<MeteorTargetComponent>()!.targetId!;
    final targetEntity = world.entities[targetId];

    if (targetEntity == null) return;

    final targetPos = targetEntity.get<PositionComponent>()!;

    final dx = meteorPos.x - targetPos.x;
    final dy = meteorPos.y - targetPos.y;
    final distance = sqrt(dx * dx + dy * dy);

    final collisionThreshold = (meteorPos.width / 2) + (targetPos.width / 2);

    if (distance < collisionThreshold) {
      final rootEntity = world.entities.values.firstWhereOrNull(
          (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);

      // --- FIX: Only award points if the game is not over ---
      // --- اصلاح: امتیاز فقط در صورتی داده می‌شود که بازی تمام نشده باشد ---
      if (rootEntity != null) {
        final blackboard = rootEntity.get<BlackboardComponent>()!;
        if (!(blackboard.get<bool>('is_game_over') ?? false)) {
          final health = targetEntity.get<HealthComponent>();
          if (health != null) {
            targetEntity.add(HealthComponent(
              maxHealth: health.maxHealth,
              currentHealth: health.currentHealth - 25,
            ));
          }
          blackboard.increment('score', 10);
          rootEntity.add(blackboard);
        }
      }

      _createCollisionExplosion(meteorPos);
      world.removeEntity(entity.id);
    }
  }

  void _createCollisionExplosion(PositionComponent atPosition) {
    for (int i = 0; i < 50; i++) {
      final debris = Entity();
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 200 + 50;

      debris.add(PositionComponent(
        x: atPosition.x,
        y: atPosition.y,
        width: 3,
        height: 3,
      ));
      debris
          .add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
      debris.add(ParticleComponent(
        maxAge: _random.nextDouble() * 2.0 + 1.0,
        initialColorValue: 0xFFFFF176,
        finalColorValue: 0xFFF44336,
      ));
      debris.add(TagsComponent({'particle'}));
      world.addEntity(debris);
    }
  }
}
