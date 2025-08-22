import 'dart:async';
import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/health_orb_component.dart';
import '../components/power_up_component.dart';

/// A system that handles the healing interaction when a player
/// collides with a health orb, now also applying a power-up.
class HealingSystem extends System {
  final Random _random = Random();

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CollisionEvent>(_onCollision);
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];

    if (entityA == null || entityB == null) return;

    // A more robust way to check for the specific collision pair
    final player = _tryGetPlayer(entityA, entityB);
    final orb = _tryGetOrb(entityA, entityB);

    if (player != null && orb != null) {
      _applyHealingAndPowerUp(player, orb);
    }
  }

  Entity? _tryGetPlayer(Entity a, Entity b) {
    if (a.get<TagsComponent>()?.hasTag('player') ?? false) return a;
    if (b.get<TagsComponent>()?.hasTag('player') ?? false) return b;
    return null;
  }

  Entity? _tryGetOrb(Entity a, Entity b) {
    if (a.has<HealthOrbComponent>()) return a;
    if (b.has<HealthOrbComponent>()) return b;
    return null;
  }

  void _applyHealingAndPowerUp(Entity player, Entity orb) {
    final playerHealth = player.get<HealthComponent>();
    if (playerHealth == null) return;

    // 1. Heal the player to full health.
    player.add(HealthComponent(maxHealth: playerHealth.maxHealth));

    // 2. Add or reset the power-up component.
    // The PowerUpSystem will handle the logic of changing the player's size.
    player.add(PowerUpComponent(duration: 5.0));

    // 3. Trigger particle explosion from the orb's position.
    final orbPos = orb.get<PositionComponent>();
    if (orbPos != null) {
      _createHealParticles(orbPos);
    }

    // 4. Remove the health orb.
    world.removeEntity(orb.id);
  }

  void _createHealParticles(PositionComponent orbPos) {
    final particleCount = _random.nextInt(10) + 15;
    for (int i = 0; i < particleCount; i++) {
      final particle = Entity();
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 80 + 40;
      final size = _random.nextDouble() * 3 + 1;
      final maxAge = _random.nextDouble() * 1.0 + 0.5;

      particle.add(PositionComponent(
        x: orbPos.x,
        y: orbPos.y,
        width: size,
        height: size,
      ));
      particle
          .add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
      particle.add(ParticleComponent(
        maxAge: maxAge,
        initialColorValue: 0xFF4CAF50, // Green
        finalColorValue: 0x00FFFFFF,
      ));
      particle.add(TagsComponent({'particle'}));
      particle.add(LifecyclePolicyComponent(
        destructionCondition: (e) {
          final p = e.get<ParticleComponent>();
          return p != null && p.age >= p.maxAge;
        },
      ));

      world.addEntity(particle);
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
