// ==============================================================================
// File: lib/systems/client_targeting_system.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A new client-side system that predicts the movement of AI
//              entities (like meteors) for a smooth visual experience.
// ==============================================================================

import 'dart:math';
import 'package:attractor_example/components/network_components.dart';
import 'package:nexus/nexus.dart';

/// A client-side system that steers entities with a `TargetingComponent`
/// towards their target.
///
/// This system runs on the client to predict the movement of non-player entities
/// between server updates, providing a smooth visual experience for everyone.
/// The server remains the authority and will correct any deviations.
class ClientTargetingSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system acts on any entity that has a target, velocity, and position.
    // It specifically excludes the locally controlled player.
    return entity.has<TargetingComponent>() &&
        entity.has<VelocityComponent>() &&
        entity.has<PositionComponent>() &&
        !entity.has<ControlledPlayerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final targeting = entity.get<TargetingComponent>()!;
    final vel = entity.get<VelocityComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    // The targetId is set by the server. We find the target entity locally.
    final targetEntity = world.entities[targeting.targetId];
    if (targetEntity == null) {
      // If the target doesn't exist on the client yet, we can't predict.
      // We'll just let the PhysicsSystem move it straight for now.
      return;
    }

    final targetPos = targetEntity.get<PositionComponent>();
    if (targetPos == null) return;

    // --- Prediction Logic (mirrors the server's logic) ---

    // Calculate the desired direction
    final desiredAngle = atan2(targetPos.y - pos.y, targetPos.x - pos.x);

    // Calculate the current direction
    final currentAngle = atan2(vel.y, vel.x);

    // Find the shortest angle to turn
    var angleDiff = desiredAngle - currentAngle;
    while (angleDiff > pi) angleDiff -= 2 * pi;
    while (angleDiff < -pi) angleDiff += 2 * pi;

    // Clamp the turn speed
    final turnAmount =
        angleDiff.clamp(-targeting.turnSpeed * dt, targeting.turnSpeed * dt);
    final newAngle = currentAngle + turnAmount;

    // Keep the current speed, but change the direction
    final speed = sqrt(vel.x * vel.x + vel.y * vel.y);
    vel.x = cos(newAngle) * speed;
    vel.y = sin(newAngle) * speed;

    entity.add(vel);
  }
}
