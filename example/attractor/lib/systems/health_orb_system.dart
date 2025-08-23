import 'package:nexus/nexus.dart';
import '../components/health_orb_component.dart';

class HealthOrbSystem extends System {
  static const double lifespan = 3.0;

  @override
  bool matches(Entity entity) {
    return entity.has<HealthOrbComponent>() && entity.has<HealthComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final health = entity.get<HealthComponent>()!;
    final damagePerSecond = health.maxHealth / lifespan;
    final newHealth = health.currentHealth - (damagePerSecond * dt);

    if (newHealth <= 0) {
      world.removeEntity(entity.id);
    } else {
      entity.add(HealthComponent(
        maxHealth: health.maxHealth,
        currentHealth: newHealth,
      ));
    }
  }
}
