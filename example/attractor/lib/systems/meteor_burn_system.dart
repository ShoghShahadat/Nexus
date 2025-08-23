import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
import '../components/score_component.dart';

class MeteorBurnSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<MeteorComponent>() && entity.has<HealthComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final health = entity.get<HealthComponent>()!;
    if (health.currentHealth <= 0) {
      _explodeAndDie(entity);
      return;
    }

    final damagePerSecond = health.maxHealth / 5.0; // 5 second lifespan
    final newHealth = health.currentHealth - (damagePerSecond * dt);

    entity.add(
        HealthComponent(maxHealth: health.maxHealth, currentHealth: newHealth));

    if (newHealth > 0) {
      final pos = entity.get<PositionComponent>()!;
      final healthRatio = newHealth / health.maxHealth;
      pos.width = 25 * healthRatio;
      pos.height = 25 * healthRatio;
      entity.add(pos);
    }
  }

  void _explodeAndDie(Entity entity) {
    final localPlayer = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('player') ?? false);
    if (localPlayer != null) {
      final score = localPlayer.get<ScoreComponent>();
      if (score != null) {
        score.score += 5;
        localPlayer.add(score);
      }
    }
    world.removeEntity(entity.id);
  }
}
