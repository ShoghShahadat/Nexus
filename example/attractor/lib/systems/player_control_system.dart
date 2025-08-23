import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../events.dart';

class PlayerControlSystem extends System {
  final _keysDown = <LogicalKeyboardKey>{};
  var _joystickVector = Offset.zero;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ClientKeyboardEvent>(_onKeyboardEvent);
    listen<JoystickUpdateEvent>(_onJoystickUpdate);
  }

  void _onKeyboardEvent(ClientKeyboardEvent event) {
    if (event.isDown)
      _keysDown.add(event.key);
    else
      _keysDown.remove(event.key);
  }

  void _onJoystickUpdate(JoystickUpdateEvent event) {
    _joystickVector = event.vector;
  }

  @override
  bool matches(Entity entity) {
    return entity.get<PlayerComponent>()?.isLocalPlayer ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    var keyboardDx = 0.0, keyboardDy = 0.0;
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
    if (distance > 1.0) finalVector = finalVector / distance;

    final vel = entity.get<VelocityComponent>()!;
    final moveSpeed = 300.0;
    final newVelX = finalVector.dx * moveSpeed;
    final newVelY = finalVector.dy * moveSpeed;

    if (vel.x != newVelX || vel.y != newVelY) {
      vel.x = newVelX;
      vel.y = newVelY;
      entity.add(vel);
      // --- P2P: Broadcast the new velocity to other clients ---
      world.eventBus.fire(RelayComponentStateEvent(entity.id, vel));
    }
  }
}
