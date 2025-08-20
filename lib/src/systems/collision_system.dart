import 'dart:math';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/gameplay_components.dart';
import 'package:nexus/src/events/gameplay_events.dart';

/// A system that detects collisions between entities with `CollisionComponent`.
/// سیستمی که برخورد بین موجودیت‌های دارای `CollisionComponent` را تشخیص می‌دهد.
class CollisionSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<CollisionComponent>() && entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // This system uses a brute-force N^2 check. For a real game, a spatial
    // partitioning grid would be more efficient.
    // این سیستم از یک بررسی N^2 استفاده می‌کند. برای یک بازی واقعی، یک گرید
    // پارتیشن‌بندی فضایی کارآمدتر خواهد بود.

    final collA = entity.get<CollisionComponent>()!;
    final posA = entity.get<PositionComponent>()!;

    // Iterate through all other collidable entities
    // تمام موجودیت‌های قابل برخورد دیگر را پیمایش می‌کند
    for (final otherEntity in world.entities.values) {
      // Don't collide with self
      // با خودش برخورد نکند
      if (entity.id == otherEntity.id) continue;
      if (!matches(otherEntity)) continue;

      final collB = otherEntity.get<CollisionComponent>()!;
      final posB = otherEntity.get<PositionComponent>()!;

      // Check if they are interested in colliding with each other
      // بررسی می‌کند که آیا به برخورد با یکدیگر علاقه‌مند هستند یا خیر
      final canCollide = collA.collidesWith.contains(collB.tag) ||
          collB.collidesWith.contains(collA.tag);

      if (!canCollide) continue;

      // Simple circle collision check
      // بررسی برخورد دایره‌ای ساده
      if (collA.shape == CollisionShape.circle &&
          collB.shape == CollisionShape.circle) {
        final dx = posA.x - posB.x;
        final dy = posA.y - posB.y;
        final distanceSq = dx * dx + dy * dy;
        final combinedRadius = collA.radius + collB.radius;

        if (distanceSq < combinedRadius * combinedRadius) {
          // Fire a collision event, but only once per pair.
          // یک رویداد برخورد منتشر می‌کند، اما فقط یک بار برای هر جفت.
          if (entity.id < otherEntity.id) {
            world.eventBus.fire(CollisionEvent(entity.id, otherEntity.id));
          }
        }
      }
    }
  }
}
