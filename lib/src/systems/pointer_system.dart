import 'dart:async';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';
import 'package:nexus/src/events/pointer_events.dart';

/// A system that listens for pointer events from the UI and updates the
/// position of a designated entity (like the attractor).
class PointerSystem extends System {
  StreamSubscription? _pointerMoveSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _pointerMoveSubscription =
        world.eventBus.on<NexusPointerMoveEvent>(_onPointerMove);
  }

  void _onPointerMove(NexusPointerMoveEvent event) {
    // --- FIX: Removed flawed caching. Find the attractor on every event. ---
    // This is robust and prevents race conditions during initialization.
    final trackedEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());

    if (trackedEntity != null) {
      final pos = trackedEntity.get<PositionComponent>()!;
      pos.x = event.x;
      pos.y = event.y;
      trackedEntity.add(pos);
    }
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}

  @override
  void onRemovedFromWorld() {
    _pointerMoveSubscription?.cancel();
    _pointerMoveSubscription = null;
    super.onRemovedFromWorld();
  }
}
