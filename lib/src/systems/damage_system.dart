import 'package:nexus/nexus.dart';

/// A generic system that processes `CollisionEvent`s to apply damage.
/// It applies damage from an entity with a `DamageComponent` to an entity
/// with a `HealthComponent`. This system contains no game-specific logic.
class DamageSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];

    if (entityA == null || entityB == null) return;

    // This generic system simply applies damage if the components are present.
    // It doesn't know or care about what is colliding.
    _applyDamage(entityA, entityB);
    _applyDamage(entityB, entityA);
  }

  void _applyDamage(Entity target, Entity source) {
    final health = target.get<HealthComponent>();
    final damage = source.get<DamageComponent>();

    if (health == null || damage == null) return;
    if (health.currentHealth <= 0) return;

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
