// ==============================================================================
// File: lib/systems/player_control_system.dart
// Author: Your Intelligent Assistant
// Version: 2.0
// Description: Reads local input and sends it to the server.
// Changes:
// - CRITICAL: Now implements Client-Side Prediction. It directly modifies
//   the local player's velocity for immediate, responsive movement.
// ==============================================================================

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../events.dart';

/// A client-side system that reads local input (keyboard and joystick).
/// It implements Client-Side Prediction by applying velocity changes directly
/// to the locally controlled player entity for immediate feedback, while also
/// sending the input to the server for authoritative processing.
class PlayerControlSystem extends System {
  final _keysDown = <LogicalKeyboardKey>{};
  var _joystickVector = Offset.zero;
  var _lastSentVector = Offset.zero;
  static const double playerSpeed = 300.0; // Same as server speed

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ClientKeyboardEvent>(_onKeyboardEvent);
    listen<JoystickUpdateEvent>(_onJoystickUpdate);
  }

  void _onKeyboardEvent(ClientKeyboardEvent event) {
    if (event.isDown) {
      _keysDown.add(event.key);
    } else {
      _keysDown.remove(event.key);
    }
  }

  void _onJoystickUpdate(JoystickUpdateEvent event) {
    _joystickVector = event.vector;
  }

  @override
  bool matches(Entity entity) {
    // This system now runs on the root entity to process input,
    // but it acts upon the local player entity.
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // 1. Calculate final input vector
    var keyboardDx = 0.0;
    var keyboardDy = 0.0;
    if (_keysDown.contains(LogicalKeyboardKey.arrowLeft) ||
        _keysDown.contains(LogicalKeyboardKey.keyA)) keyboardDx -= 1.0;
    if (_keysDown.contains(LogicalKeyboardKey.arrowRight) ||
        _keysDown.contains(LogicalKeyboardKey.keyD)) keyboardDx += 1.0;
    if (_keysDown.contains(LogicalKeyboardKey.arrowUp) ||
        _keysDown.contains(LogicalKeyboardKey.keyW)) keyboardDy -= 1.0;
    if (_keysDown.contains(LogicalKeyboardKey.arrowDown) ||
        _keysDown.contains(LogicalKeyboardKey.keyS)) keyboardDy += 1.0;

    var finalVector = _joystickVector.distance > 0
        ? _joystickVector
        : Offset(keyboardDx, keyboardDy);

    final distance = finalVector.distance;
    if (distance > 1.0) {
      finalVector = finalVector / distance;
    }

    // 2. Send input to server if it has changed
    if (finalVector != _lastSentVector) {
      world.eventBus
          .fire(SendDirectionalInputEvent(finalVector.dx, finalVector.dy));
      _lastSentVector = finalVector;
    }

    // 3. --- CLIENT-SIDE PREDICTION ---
    // Find the local player entity and apply the velocity directly.
    final localPlayerId = world.rootEntity
        .get<BlackboardComponent>()
        ?.get<EntityId>('local_player_id');
    if (localPlayerId != null) {
      final playerEntity = world.entities[localPlayerId];
      if (playerEntity != null) {
        final vel =
            playerEntity.get<VelocityComponent>() ?? VelocityComponent();
        vel.x = finalVector.dx * playerSpeed;
        vel.y = finalVector.dy * playerSpeed;
        playerEntity.add(vel);
      }
    }
  }
}
