import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';

/// A system that processes `CollisionEvent`s to apply damage to entities
/// with a `HealthComponent`. It also handles special collision cases,
/// like meteor-on-meteor destruction.
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

    // --- FIX: Handle meteor-on-meteor collision ---
    final isAMeteor = entityA.has<MeteorComponent>();
    final isBMeteor = entityB.has<MeteorComponent>();

    if (isAMeteor && isBMeteor) {
      // Both are meteors, destroy them both.
      // Setting health to 0 will trigger their respective destruction logic.
      entityA.add(HealthComponent(maxHealth: 1, currentHealth: 0));
      entityB.add(HealthComponent(maxHealth: 1, currentHealth: 0));
      return; // Stop further processing for this pair
    }

    // Standard damage logic
    _applyDamage(entityA, entityB);
    _applyDamage(entityB, entityA);
  }

  void _applyDamage(Entity target, Entity source) {
    final health = target.get<HealthComponent>();
    final damage = source.get<DamageComponent>();

    if (health == null || damage == null) return;

    // Avoid applying damage if the target is already defeated
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
