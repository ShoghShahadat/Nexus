import 'package:nexus/nexus.dart';

/// A system that listens for shape selection events and triggers morphing animations.
/// This system is now fully isolate-safe and handles animation interruptions.
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

    // Forcefully cancel any ongoing morph animation on this entity.
    // This prevents race conditions from rapid clicks.
    counterEntity.remove<AnimationComponent>();
    counterEntity.remove<AnimationProgressComponent>();

    final currentMorph = counterEntity.get<MorphingLogicComponent>()!;

    // The new animation should start from wherever the last animation was heading.
    final newStartSides = currentMorph.targetSides;

    // If the user clicks the same shape they are already on, do nothing.
    if (newStartSides == event.targetSides) return;

    // Trigger a new morph by updating the component with the new target.
    counterEntity.add(MorphingLogicComponent(
      initialSides: newStartSides,
      targetSides: event.targetSides,
    ));
  }

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
