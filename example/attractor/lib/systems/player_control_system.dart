import 'dart:async';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../events.dart';

/// A client-side system that reads local input (pointer/mouse) and sends it
/// to the server via events.
class PlayerControlSystem extends System {
  StreamSubscription? _pointerMoveSubscription;
  double _lastSentX = 0;
  double _lastSentY = 0;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _pointerMoveSubscription =
        world.eventBus.on<NexusPointerMoveEvent>(_onPointerMove);
  }

  void _onPointerMove(NexusPointerMoveEvent event) {
    // To avoid flooding the network, we could add some throttling here,
    // but for a local mock server, it's fine to send every event.
    if ((event.x - _lastSentX).abs() > 1 || (event.y - _lastSentY).abs() > 1) {
      world.eventBus.fire(SendInputEvent(event.x, event.y));
      _lastSentX = event.x;
      _lastSentY = event.y;
    }
  }

  @override
  bool matches(Entity entity) {
    // This system doesn't need to process any entities in the update loop.
    return false;
  }

  @override
  void update(Entity entity, double dt) {}

  @override
  void onRemovedFromWorld() {
    _pointerMoveSubscription?.cancel();
    super.onRemovedFromWorld();
  }
}
