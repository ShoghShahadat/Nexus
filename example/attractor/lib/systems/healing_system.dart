import 'dart:async';
import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/health_orb_component.dart';

/// A system that handles the healing interaction when the attractor
/// collides with a health orb.
class HealingSystem extends System {
  final Random _random = Random();
  StreamSubscription? _collisionSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _collisionSubscription = world.eventBus.on<CollisionEvent>(_onCollision);
  }

  @override
  void onRemovedFromWorld() {
    _collisionSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onCollision(CollisionEvent event) {
    final entityA = world.entities[event.entityA];
    final entityB = world.entities[event.entityB];

    if (entityA == null || entityB == null) return;

    // Check for attractor-orb collision
    _handleHealing(entityA, entityB);
    _handleHealing(entityB, entityA);
  }

  void _handleHealing(Entity entity1, Entity entity2) {
    final isEntity1Attractor =
        entity1.get<TagsComponent>()?.hasTag('attractor') ?? false;
    final isEntity2Orb = entity2.has<HealthOrbComponent>();

    if (isEntity1Attractor && isEntity2Orb) {
      final attractorHealth = entity1.get<HealthComponent>();
      if (attractorHealth == null) return;

      // Heal the attractor to full health.
      entity1.add(HealthComponent(maxHealth: attractorHealth.maxHealth));

      // Trigger particle explosion from the orb's position.
      final orbPos = entity2.get<PositionComponent>();
      if (orbPos != null) {
        _createHealParticles(orbPos);
      }

      // Remove the health orb.
      world.removeEntity(entity2.id);
    }
  }

  void _createHealParticles(PositionComponent orbPos) {
    // Create 15-25 small particles bursting outwards.
    final particleCount = _random.nextInt(10) + 15;
    for (int i = 0; i < particleCount; i++) {
      final particle = Entity();
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 80 + 40; // Speed between 40 and 120
      final size = _random.nextDouble() * 3 + 1; // Size between 1 and 4

      particle.add(PositionComponent(
        x: orbPos.x,
        y: orbPos.y,
        width: size,
        height: size,
      ));
      particle
          .add(VelocityComponent(x: cos(angle) * speed, y: sin(angle) * speed));
      particle.add(ParticleComponent(
        maxAge: _random.nextDouble() * 1.0 + 0.5, // Lifespan 0.5s to 1.5s
        initialColorValue: 0xFF4CAF50, // Green
        finalColorValue: 0x00FFFFFF, // Fade to transparent
      ));
      particle.add(TagsComponent({'particle'}));
      world.addEntity(particle);
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
