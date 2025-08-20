import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/complex_movement_component.dart';

/// A system, defined locally, that applies complex movement patterns to particles.
class ComplexMovementSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system only operates on entities that have both a velocity and a complex movement pattern.
    return entity.has<VelocityComponent>() &&
        entity.has<ComplexMovementComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final vel = entity.get<VelocityComponent>()!;
    final movement = entity.get<ComplexMovementComponent>()!;

    // Increment the internal clock for this particle's movement.
    movement.time += dt;

    switch (movement.type) {
      case MovementType.SineWave:
        // Create a wave-like motion perpendicular to the current direction.
        final velMag = sqrt(vel.x * vel.x + vel.y * vel.y);
        if (velMag > 0.1) {
          // Calculate the normalized perpendicular vector.
          final perpX = -vel.y / velMag;
          final perpY = vel.x / velMag;

          // Calculate the force along the perpendicular vector based on a sine wave.
          final sineForce =
              sin(movement.time * movement.frequency) * movement.amplitude;

          // Apply this force as an acceleration.
          vel.x += perpX * sineForce * dt;
          vel.y += perpY * sineForce * dt;
        }
        break;
      case MovementType.Spiral:
        // Create a gentle spiraling motion by rotating the velocity vector.
        final rotationSpeed = movement.frequency * 0.5;
        vel.x += -vel.y * rotationSpeed * dt;
        vel.y += vel.x * rotationSpeed * dt;
        break;
    }

    // Add the components back to notify the world of the changes.
    entity.add(vel);
    entity.add(movement);
  }
}
