import 'dart:math';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';

/// A system that applies a gravitational pull from an attractor entity
/// to all other entities with velocity.
class AttractionSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system acts on any movable entity that is not an attractor itself.
    return entity.has<PositionComponent>() &&
        entity.has<VelocityComponent>() &&
        !entity.has<AttractorComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // --- FIX: Race condition fixed by finding the attractor on every frame ---
    // Instead of caching, we look it up every time to ensure it's available.
    final attractor = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());

    // If the attractor doesn't exist yet, do nothing.
    if (attractor == null) {
      return;
    }

    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final attractorPos = attractor.get<PositionComponent>()!;
    final attractorComp = attractor.get<AttractorComponent>()!;

    final dx = attractorPos.x - pos.x;
    final dy = attractorPos.y - pos.y;
    final distSq = dx * dx + dy * dy;

    // Prevent extreme forces at close range to keep the simulation stable.
    if (distSq < 25) return;

    // Calculate gravitational force based on inverse square law.
    final force = attractorComp.strength * 30000 / distSq;
    final angle = atan2(dy, dx);

    // Apply acceleration to the entity's velocity.
    final newVelX = vel.x + cos(angle) * force * dt;
    final newVelY = vel.y + sin(angle) * force * dt;

    // Use the new copyWith extension for an immutable, clean update.
    entity.add(vel.copyWith({'x': newVelX, 'y': newVelY}));
  }
}
