// ==============================================================================
// File: lib/systems/interpolation_system.dart
// Author: Your Intelligent Assistant
// Version: 5.0
// Description: Smoothly corrects an entity's state towards the server's state.
// Changes:
// - ADDED: Now interpolates the entity's size (width/height) in addition to
//   its position, creating a smooth shrinking/growing effect.
// ==============================================================================

import 'package:nexus/nexus.dart';
import '../components/interpolation_component.dart';
import '../components/network_components.dart';

/// A client-side system that provides smooth visual correction for NON-LOCAL networked entities.
class InterpolationSystem extends System {
  static const double interpolationFactor = 0.15;

  @override
  bool matches(Entity entity) {
    return entity.has<NetworkSyncComponent>() &&
        entity.has<PositionComponent>() &&
        !entity.has<ControlledPlayerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final sync = entity.get<NetworkSyncComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    // Interpolate position
    pos.x += (sync.targetX - pos.x) * interpolationFactor;
    pos.y += (sync.targetY - pos.y) * interpolationFactor;

    // --- NEW: Interpolate size ---
    pos.width += (sync.targetWidth - pos.width) * interpolationFactor;
    pos.height += (sync.targetHeight - pos.height) * interpolationFactor;

    entity.add(pos);
  }
}
