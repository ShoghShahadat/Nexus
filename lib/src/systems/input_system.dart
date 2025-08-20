import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/input_events.dart';

/// A system that listens for input events sent from the UI thread and
/// triggers the corresponding logic in the background isolate.
class InputSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for tap events coming from the UI.
    world.eventBus.on<EntityTapEvent>(_onTap);
  }

  /// Handles the tap event.
  void _onTap(EntityTapEvent event) {
    // Find the entity that was tapped.
    final entity = world.entities[event.id];
    if (entity == null) return;

    // If it has a ClickableComponent, execute its onTap callback.
    final clickable = entity.get<ClickableComponent>();
    clickable?.onTap(entity);
  }

  // This system is purely event-driven and does not need to process
  // entities in the main update loop.
  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
