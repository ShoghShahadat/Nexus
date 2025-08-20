import 'package:nexus/nexus.dart';

/// A system that listens for shape selection events and triggers morphing animations.
/// This system is now fully isolate-safe.
class ShapeSelectionSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<ShapeSelectedEvent>(_onShapeSelected);
  }

  void _onShapeSelected(ShapeSelectedEvent event) {
    final counterEntity = world.entities.values.firstWhere(
      (e) => e.get<TagsComponent>()?.hasTag('counter_display') ?? false,
      orElse: () => throw Exception("No counter display entity found!"),
    );

    final currentMorph = counterEntity.get<MorphingLogicComponent>()!;
    // Trigger a new morph by updating the component with the new target.
    counterEntity.add(MorphingLogicComponent(
      initialSides: currentMorph.targetSides, // Start from the last shape
      targetSides: event.targetSides,
    ));
  }

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
