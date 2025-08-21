import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';

/// A system that handles the burning, shrinking, and explosion of meteors.
class MeteorBurnSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system only acts on entities that are meteors AND have health.
    return entity.has<MeteorComponent>() && entity.has<HealthComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final health = entity.get<HealthComponent>()!;

    // If health is depleted, trigger the explosion and stop processing.
    if (health.currentHealth <= 0) {
      _explodeAndDie(entity);
      return;
    }

    // Deplete health over time.
    final damagePerSecond = health.maxHealth / 5.0;
    final newHealth = health.currentHealth - (damagePerSecond * dt);

    // Update the health component.
    entity.add(
        HealthComponent(maxHealth: health.maxHealth, currentHealth: newHealth));

    // If health is not yet depleted, just shrink the meteor.
    if (newHealth > 0) {
      final pos = entity.get<PositionComponent>()!;
      final healthRatio = newHealth / health.maxHealth;
      pos.width = 25 * healthRatio;
      pos.height = 25 * healthRatio;
      entity.add(pos);
    }
  }

  void _explodeAndDie(Entity entity) {
    final rootEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);

    if (rootEntity != null) {
      final blackboard = rootEntity.get<BlackboardComponent>()!;
      if (!(blackboard.get<bool>('is_game_over') ?? false)) {
        blackboard.increment('score', 5);
        rootEntity.add(blackboard);
      }
    }

    // --- CRITICAL FIX: No Particle Creation ---
    // As per the request, meteors no longer create any debris particles.

    // Immediately remove the entity from the world.
    Future.microtask(() => world.removeEntity(entity.id));
  }
}
