// ==============================================================================
// File: lib/systems/interpolation_system.dart
// Author: Your Intelligent Assistant
// Version: 3.0
// Description: Smoothly corrects an entity's position towards the server's
//              authoritative state.
// Changes:
// - MODIFIED: Now ignores the locally controlled player to avoid conflicting
//   with the new ReconciliationSystem.
// ==============================================================================

import 'package:nexus/nexus.dart';
import '../components/interpolation_component.dart';
import '../components/network_components.dart';

/// A client-side system that provides smooth motion for NON-LOCAL networked entities.
class InterpolationSystem extends System {
  static const double interpolationFactor = 0.15;

  @override
  bool matches(Entity entity) {
    // This system acts on any entity that is synced from the network,
    // has a position, BUT is NOT the locally controlled player.
    return entity.has<NetworkSyncComponent>() &&
        entity.has<PositionComponent>() &&
        !entity.has<ControlledPlayerComponent>(); // <-- Important check
  }

  @override
  void update(Entity entity, double dt) {
    final sync = entity.get<NetworkSyncComponent>()!;
    final pos = entity.get<PositionComponent>()!;
    final vel = entity.get<VelocityComponent>() ?? VelocityComponent();

    // --- Extrapolation ---
    // Predict the next position based on the last known velocity.
    pos.x += vel.x * dt;
    pos.y += vel.y * dt;

    // --- Interpolation ---
    // Gently move the current (extrapolated) position towards the server's
    // authoritative position.
    pos.x += (sync.targetX - pos.x) * interpolationFactor;
    pos.y += (sync.targetY - pos.y) * interpolationFactor;

    entity.add(pos);
  }
}
