import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/components/meteor_component.dart';
import 'package:nexus_example/components/meteor_target_component.dart';

/// A system that checks for collisions between homing meteors and their targets.
/// Renamed to avoid conflict with the core CollisionSystem.
/// سیستمی که برخورد بین شهاب‌سنگ‌های هدایت‌شونده و اهدافشان را بررسی می‌کند.
/// برای جلوگیری از تداخل با CollisionSystem هسته، تغییر نام داده شد.
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
      // --- NEW: Apply damage and award points on collision ---
      // --- جدید: اعمال آسیب و اهدای امتیاز در برخورد ---
      final health = targetEntity.get<HealthComponent>();
      if (health != null) {
        targetEntity.add(HealthComponent(
          maxHealth: health.maxHealth,
          currentHealth: health.currentHealth - 25, // Each hit costs 25 HP
        ));
      }

      final rootEntity = world.entities.values.firstWhereOrNull(
          (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);
      if (rootEntity != null) {
        final blackboard = rootEntity.get<BlackboardComponent>()!;
        blackboard.increment('score', 10); // 10 points for a direct hit
        rootEntity.add(blackboard);
      }

      _createCollisionExplosion(meteorPos);
      world.removeEntity(entity.id); // Destroy the meteor.
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
