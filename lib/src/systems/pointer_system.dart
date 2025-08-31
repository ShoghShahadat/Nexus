import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';

// UNNECESSARY IMPORTS REMOVED: Redundant imports were cleaned up as requested by the analyzer.

/// A system that listens for pointer events from the UI and updates the
/// position of a designated entity (like the attractor).
class PointerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<NexusPointerMoveEvent>(_onPointerMove);
  }

  void _onPointerMove(NexusPointerMoveEvent event) {
    // --- FIX: Removed flawed caching. Find the attractor on every event. ---
    // This is robust and prevents race conditions during initialization.
    final trackedEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());

    if (trackedEntity != null) {
      final pos = trackedEntity.get<PositionComponent>()!;
      // FINAL FIX: Correctly call the member 'copyWith' with named arguments.
      // This resolves the 'extra_positional_arguments_could_be_named' error
      // because PositionComponent has its own specific, type-safe copyWith method.
      trackedEntity.add(pos.copyWith(x: event.x, y: event.y));
    }
  }
}
