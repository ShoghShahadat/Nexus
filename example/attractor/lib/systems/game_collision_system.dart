import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';

/// A game-specific system to handle custom collision logic.
/// This system listens for collision events and applies rules unique to this game,
/// such as destroying meteors when they collide with each other.
class GameCollisionSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];

    if (entityA == null || entityB == null) return;

    final isAMeteor = entityA.has<MeteorComponent>();
    final isBMeteor = entityB.has<MeteorComponent>();

    // If two meteors collide, destroy them both immediately.
    if (isAMeteor && isBMeteor) {
      // Setting health to 0 will trigger their destruction logic
      // in the MeteorBurnSystem.
      entityA.add(HealthComponent(maxHealth: 1, currentHealth: 0));
      entityB.add(HealthComponent(maxHealth: 1, currentHealth: 0));
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
