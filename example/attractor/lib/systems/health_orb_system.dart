import 'package:nexus/nexus.dart';
import '../components/health_orb_component.dart';

/// A system that manages the lifecycle of health orbs.
/// It depletes their health over a fixed duration (e.g., 3 seconds),
/// and removes them if their health reaches zero.
class HealthOrbSystem extends System {
  // Total lifespan of the orb in seconds.
  static const double lifespan = 3.0;

  @override
  bool matches(Entity entity) {
    return entity.has<HealthOrbComponent>() && entity.has<HealthComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final health = entity.get<HealthComponent>()!;

    // Calculate damage per second based on lifespan.
    final damagePerSecond = health.maxHealth / lifespan;
    final newHealth = health.currentHealth - (damagePerSecond * dt);

    if (newHealth <= 0) {
      // If health is depleted, remove the orb.
      world.removeEntity(entity.id);
    } else {
      // Otherwise, update its health.
      entity.add(HealthComponent(
        maxHealth: health.maxHealth,
        currentHealth: newHealth,
      ));
    }
  }
}
