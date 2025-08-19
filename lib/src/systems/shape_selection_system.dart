import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/shape_events.dart'; // Corrected import path

/// A system that listens for shape selection events and triggers morphing animations.
///
/// This system demonstrates decoupled, event-driven architecture. It has no
/// direct knowledge of the UI buttons. It only reacts to events on the EventBus.
class ShapeSelectionSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Subscribe to the event bus when the system is added to the world.
    world.eventBus.on<ShapeSelectedEvent>(_onShapeSelected);
  }

  void _onShapeSelected(ShapeSelectedEvent event) {
    // Find the entity that should be morphed (the counter display).
    final counterEntity = world.entities.values.firstWhere(
      (e) =>
          e.has<TagsComponent>() &&
          e.get<TagsComponent>()!.hasTag('counter_display'),
      orElse: () => throw Exception("No counter display entity found!"),
    );

    // Get its current shape and trigger a new morphing animation.
    final currentPath = counterEntity.get<MorphingComponent>()!.currentPath;
    counterEntity.add(MorphingComponent(
      initialPath: currentPath,
      targetPath: event.targetPath,
    ));
  }

  // This system is purely event-driven, so these methods are not used.
  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
