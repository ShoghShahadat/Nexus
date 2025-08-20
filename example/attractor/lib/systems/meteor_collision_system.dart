import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/meteor_target_component.dart';

/// A system that checks for collisions between homing meteors and their targets.
/// Renamed to avoid conflict with the core CollisionSystem.
/// سیستمی که برخورد بین شهاب‌سنگ‌های هدایت‌شونده و اهدافشان را بررسی می‌کند.
/// برای جلوگیری از تداخل با CollisionSystem هسته، تغییر نام داده شد.
class MeteorCollisionSystem extends System {
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system only cares about meteors that are actively targeting something.
    // این سیستم فقط به شهاب‌سنگ‌هایی که به طور فعال هدفی را دنبال می‌کنند، اهمیت می‌دهد.
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

    if (targetEntity == null) return; // Target no longer exists.

    final targetPos = targetEntity.get<PositionComponent>()!;

    final dx = meteorPos.x - targetPos.x;
    final dy = meteorPos.y - targetPos.y;
    final distance = sqrt(dx * dx + dy * dy);

    final collisionThreshold = (meteorPos.width / 2) + (targetPos.width / 2);

    if (distance < collisionThreshold) {
      // Collision detected!
      _createCollisionExplosion(meteorPos);
      world.removeEntity(entity.id); // Destroy the meteor.
    }
  }

  /// Creates a spectacular burst of particles at the collision point.
  /// یک انفجار دیدنی از ذرات در نقطه برخورد ایجاد می‌کند.
  void _createCollisionExplosion(PositionComponent atPosition) {
    for (int i = 0; i < 50; i++) {
      // Create 50 particles for a big explosion
      final debris = Entity();
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 200 + 50; // Fast-moving debris

      debris.add(PositionComponent(
        x: atPosition.x,
        y: atPosition.y,
        width: 3,
        height: 3,
      ));
      debris
          .add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
      debris.add(ParticleComponent(
        maxAge: _random.nextDouble() * 2.0 + 1.0, // Debris lasts 1-3s
        initialColorValue: 0xFFFFF176, // Bright Yellow
        finalColorValue: 0xFFF44336, // Fades to Red
      ));
      debris.add(TagsComponent({'particle'}));
      world.addEntity(debris);
    }
  }
}
