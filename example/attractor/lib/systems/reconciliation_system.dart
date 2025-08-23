// ==============================================================================
// File: lib/systems/reconciliation_system.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A new system that smoothly reconciles the local player's
//              predicted state with the server's authoritative state.
// ==============================================================================

import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../components/reconciliation_component.dart';

/// A client-side system that handles "Server Reconciliation".
///
/// It runs ONLY on the locally controlled player. Its job is to smoothly
/// correct the player's position if the client's prediction (managed by
/// PlayerControlSystem and PhysicsSystem) deviates from the server's
/// authoritative state (stored in the ReconciliationComponent).
class ReconciliationSystem extends System {
  /// The factor determining how quickly the client corrects its position.
  /// A smaller value leads to a smoother, more gradual correction.
  static const double correctionFactor = 0.1;

  @override
  bool matches(Entity entity) {
    // This system only runs on the entity that is the local player AND
    // has received a correction state from the server.
    return entity.has<ControlledPlayerComponent>() &&
        entity.has<ReconciliationComponent>() &&
        entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final reconciliation = entity.get<ReconciliationComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    // Calculate the difference between the client's current predicted position
    // and the server's authoritative position.
    final dx = reconciliation.serverX - pos.x;
    final dy = reconciliation.serverY - pos.y;

    // If the difference is negligible, we don't need to correct.
    if ((dx * dx + dy * dy) < 0.1) {
      entity.remove<ReconciliationComponent>(); // Correction is done.
      return;
    }

    // Smoothly interpolate the client's position towards the server's position.
    // This avoids jarring "snaps" and makes corrections feel natural.
    pos.x += dx * correctionFactor;
    pos.y += dy * correctionFactor;

    entity.add(pos);
  }
}
