import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/gameplay_components.dart';
import 'package:nexus/src/events/gameplay_events.dart';

/// A system that processes `CollisionEvent`s to apply damage to entities
/// with a `HealthComponent`.
/// سیستمی که رویدادهای `CollisionEvent` را برای اعمال آسیب به موجودیت‌های
/// دارای `HealthComponent` پردازش می‌کند.
class DamageSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];

    if (entityA == null || entityB == null) return;

    _applyDamage(entityA, entityB);
    _applyDamage(entityB, entityA);
  }

  void _applyDamage(Entity target, Entity source) {
    final health = target.get<HealthComponent>();
    final damage = source.get<DamageComponent>();

    if (health == null || damage == null) return;

    final newHealth = health.currentHealth - damage.damage;

    if (newHealth <= 0) {
      // The entity is destroyed.
      // موجودیت نابود شد.
      world.removeEntity(target.id);
    } else {
      // Update the health component.
      // کامپوننت سلامتی را به‌روز می‌کند.
      target.add(HealthComponent(
        maxHealth: health.maxHealth,
        currentHealth: newHealth,
      ));
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
