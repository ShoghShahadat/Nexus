import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import '../events.dart';

/// A client-side system that reads local input (keyboard and joystick)
/// and sends a normalized directional vector to the server.
class PlayerControlSystem extends System {
  final _keysDown = <LogicalKeyboardKey>{};
  var _joystickVector = Offset.zero;
  var _lastSentVector = Offset.zero;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // --- FIX: Listen for the correct, core-library events ---
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
    // This system runs once per frame, tied to the root entity.
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // 1. Calculate keyboard vector
    var keyboardDx = 0.0;
    var keyboardDy = 0.0;
    if (_keysDown.contains(LogicalKeyboardKey.arrowLeft) ||
        _keysDown.contains(LogicalKeyboardKey.keyA)) {
      keyboardDx -= 1.0;
    }
    if (_keysDown.contains(LogicalKeyboardKey.arrowRight) ||
        _keysDown.contains(LogicalKeyboardKey.keyD)) {
      keyboardDx += 1.0;
    }
    if (_keysDown.contains(LogicalKeyboardKey.arrowUp) ||
        _keysDown.contains(LogicalKeyboardKey.keyW)) {
      keyboardDy -= 1.0;
    }
    if (_keysDown.contains(LogicalKeyboardKey.arrowDown) ||
        _keysDown.contains(LogicalKeyboardKey.keyS)) {
      keyboardDy += 1.0;
    }
    final keyboardVector = Offset(keyboardDx, keyboardDy);

    // 2. Determine final input vector (joystick takes precedence)
    var finalVector =
        _joystickVector.distance > 0 ? _joystickVector : keyboardVector;

    // 3. Normalize the vector if its magnitude is greater than 1
    final distance = finalVector.distance;
    if (distance > 1.0) {
      finalVector = finalVector / distance;
    }

    // 4. Send to server only if it has changed
    if (finalVector != _lastSentVector) {
      // --- FIX: Fire the correct, game-specific event ---
      world.eventBus
          .fire(SendDirectionalInputEvent(finalVector.dx, finalVector.dy));
      _lastSentVector = finalVector;
    }
  }
}
