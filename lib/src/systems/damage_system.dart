import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/gameplay_components.dart';
import 'package:nexus/src/events/gameplay_events.dart';

/// A system that processes `CollisionEvent`s to apply damage to entities
/// with a `HealthComponent`.
/// This version uses the new `listen` helper for automatic subscription management.
class DamageSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Use the new, safer `listen` method. No need to manage the subscription manually.
    listen<CollisionEvent>(_onCollision);
  }

  // No need for onRemovedFromWorld anymore, the base class handles it!

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

    target.add(HealthComponent(
      maxHealth: health.maxHealth,
      currentHealth: newHealth,
    ));
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
