import 'package:nexus/nexus.dart';

/// A game-specific system to handle custom collision logic.
/// This system listens for collision events and applies rules unique to this game.
class GameRulesSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];

    if (entityA == null || entityB == null) return;

    final tagsA = entityA.get<TagsComponent>();
    final tagsB = entityB.get<TagsComponent>();

    final isAMeteor = tagsA?.hasTag('meteor') ?? false;
    final isBMeteor = tagsB?.hasTag('meteor') ?? false;
    final isAPlayer = tagsA?.hasTag('player') ?? false;
    final isBPlayer = tagsB?.hasTag('player') ?? false;

    // Rule 1: Meteor hits Player -> Destroy Meteor
    // The generic DamageSystem will handle the actual damage to the player.
    // This system just handles the game rule that the meteor should be destroyed.
    if ((isAMeteor && isBPlayer)) {
      entityA.add(HealthComponent(maxHealth: 1, currentHealth: 0));
    }
    if ((isBMeteor && isAPlayer)) {
      entityB.add(HealthComponent(maxHealth: 1, currentHealth: 0));
    }

    // Rule 2: Meteor hits Meteor -> Destroy both
    if (isAMeteor && isBMeteor) {
      entityA.add(HealthComponent(maxHealth: 1, currentHealth: 0));
      entityB.add(HealthComponent(maxHealth: 1, currentHealth: 0));
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
