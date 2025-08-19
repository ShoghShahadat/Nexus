import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/velocity_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that applies velocity to entities to create movement.
///
/// This system looks for entities that have both a [PositionComponent] and a
/// [VelocityComponent]. In each frame, it updates the entity's position
/// based on its current velocity and the delta time. It also includes a
/// simple boundary check to prevent entities from moving off-screen.
class PhysicsSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<PositionComponent>() && entity.has<VelocityComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // We can safely use `!` because `matches` guarantees they exist.
    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>()!;

    // Update position based on velocity and delta time.
    pos.x += vel.x * dt;
    pos.y += vel.y * dt;

    // --- Simple Boundary Check ---
    // A more robust solution might involve a dedicated BoundarySystem or
    // collision components, but this is effective for simple cases.
    if (pos.y > 500) {
      pos.y = 500; // Clamp the position to the boundary line.
      entity.remove<VelocityComponent>(); // Stop all future movement.
    }

    // Re-add the component to notify the rendering system of the change.
    entity.add(pos);
  }
}
