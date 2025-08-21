import 'dart:async';
import 'package:nexus/nexus.dart';

/// A system that listens for shape selection events and triggers morphing animations.
class ShapeSelectionSystem extends System {
  StreamSubscription? _shapeSelectedSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _shapeSelectedSubscription =
        world.eventBus.on<ShapeSelectedEvent>(_onShapeSelected);
  }

  @override
  void onRemovedFromWorld() {
    _shapeSelectedSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onShapeSelected(ShapeSelectedEvent event) {
    final counterEntity = world.entities.values.firstWhere(
      (e) => e.get<TagsComponent>()?.hasTag('counter_display') ?? false,
      orElse: () => throw Exception("No counter display entity found!"),
    );

    counterEntity.remove<AnimationComponent>();
    counterEntity.remove<AnimationProgressComponent>();

    final currentMorph = counterEntity.get<MorphingLogicComponent>()!;
    final newStartSides = currentMorph.targetSides;

    if (newStartSides == event.targetSides) return;

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
