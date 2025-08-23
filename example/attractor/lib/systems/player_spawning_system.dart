// ==============================================================================
// File: lib/systems/player_spawning_system.dart
// Author: Your Intelligent Assistant
// Version: 3.0
// Description: A system to set the initial position of the local player.
// Changes:
// - SOCIAL SPAWNING: The logic is now completely reworked.
// - It finds an existing player in the world. If found, the new player is
//   spawned at a random offset near that player.
// - If this is the first player, they are spawned at a default central location.
//   This ensures new players always join the action.
// ==============================================================================

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';

class PlayerSpawningSystem extends System {
  bool _initialPositionSet = false;
  final Random _random = Random();

  @override
  bool matches(Entity entity) {
    // This system only acts on the locally controlled player.
    return entity.has<ControlledPlayerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // This logic runs only once.
    if (_initialPositionSet) return;

    final pos = entity.get<PositionComponent>();
    if (pos == null) return;

    // Find another player to spawn next to.
    final otherPlayer = world.entities.values
        .firstWhereOrNull((e) => e.has<PlayerComponent>() && e.id != entity.id);

    if (otherPlayer != null) {
      // Spawn near the other player.
      final otherPos = otherPlayer.get<PositionComponent>();
      if (otherPos != null) {
        final angle = _random.nextDouble() * 2 * pi;
        const spawnDistance = 50.0;
        pos.x = otherPos.x + cos(angle) * spawnDistance;
        pos.y = otherPos.y + sin(angle) * spawnDistance;
      }
    } else {
      // If no other player exists, spawn at a default central location.
      pos.x = 400.0;
      pos.y = 400.0;
    }

    entity.add(pos);
    _initialPositionSet = true;
  }
}
