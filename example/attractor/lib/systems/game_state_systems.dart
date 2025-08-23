import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/attractor_component.dart';
import '../components/network_components.dart';

class GameProgressionSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // This is where difficulty could increase over time
  }
}

class GameOverSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<PlayerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final health = entity.get<HealthComponent>();
    if (health != null && health.currentHealth <= 0) {
      // Handle game over for this player
    }
  }
}

class RestartSystem extends System {
  // This would handle logic for restarting a round
  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
