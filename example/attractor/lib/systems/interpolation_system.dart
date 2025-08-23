// ==============================================================================
// File: lib/systems/interpolation_system.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A new client-side system that provides smooth motion for
//              networked entities through interpolation and extrapolation.
// ==============================================================================

import 'package:nexus/nexus.dart';
import '../components/interpolation_component.dart';

/// A client-side system that provides smooth motion for networked entities.
///
/// It interpolates the entity's visual position towards the authoritative
/// position received from the server, and extrapolates movement based on the
/// last known velocity. This creates a smooth rendering even if server updates
/// are infrequent.
class InterpolationSystem extends System {
  /// How quickly to snap to the server position. A lower value results in
  /// smoother, more gradual correction. A higher value is more responsive
  /// but can appear jerky.
  static const double interpolationFactor = 0.15;

  @override
  bool matches(Entity entity) {
    // This system acts on any entity that is synced from the network
    // and has a position that needs to be visually updated.
    return entity.has<NetworkSyncComponent>() &&
        entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final sync = entity.get<NetworkSyncComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    // --- 1. Extrapolation ---
    // Predict the next position based on the last known velocity from the server.
    // This keeps the entity moving smoothly between server updates.
    pos.x += sync.velocityX * dt;
    pos.y += sync.velocityY * dt;

    // --- 2. Interpolation ---
    // Gently move the current (extrapolated) position towards the server's
    // authoritative position. This corrects any prediction errors over time
    // without snapping directly to the new location.
    pos.x += (sync.targetX - pos.x) * interpolationFactor;
    pos.y += (sync.targetY - pos.y) * interpolationFactor;

    // Re-add the position component to mark it as dirty for the renderer.
    entity.add(pos);
  }
}
