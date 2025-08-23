import 'package:nexus/nexus.dart';
import '../components/health_orb_component.dart';
import '../components/network_components.dart';

class HealingSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];
    if (entityA == null || entityB == null) return;

    _handleHealing(entityA, entityB);
    _handleHealing(entityB, entityA);
  }

  void _handleHealing(Entity entity1, Entity entity2) {
    final isPlayer = entity1.has<PlayerComponent>();
    final isOrb = entity2.has<HealthOrbComponent>();

    if (isPlayer && isOrb) {
      final playerHealth = entity1.get<HealthComponent>();
      if (playerHealth != null) {
        entity1.add(HealthComponent(maxHealth: playerHealth.maxHealth));
      }
      world.removeEntity(entity2.id);
    }
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
