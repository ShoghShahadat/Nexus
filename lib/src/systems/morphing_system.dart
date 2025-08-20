import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';

/// A system that drives path morphing animations in the background isolate.
///
/// This system watches for changes in the [MorphingLogicComponent] and creates
/// an [AnimationComponent] to handle the timing of the morph. It updates an
/// [AnimationProgressComponent] to communicate the animation's state to the UI.
class MorphingSystem extends System {
  @override
  bool matches(Entity entity) {
    // We want to process entities that have a morph description but are not
    // currently being animated by this system.
    return entity.has<MorphingLogicComponent>() &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final morph = entity.get<MorphingLogicComponent>()!;

    // If the shape is already at its target, do nothing.
    if (morph.initialSides == morph.targetSides) {
      return;
    }

    entity.add(AnimationComponent(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      onUpdate: (e, value) {
        // On each frame, update the progress component to notify the UI.
        e.add(AnimationProgressComponent(value));
      },
      onComplete: (e) {
        // When done, solidify the shape in its final state by updating the
        // initialSides to match the targetSides.
        final finalMorph = MorphingLogicComponent(
          initialSides: morph.targetSides,
          targetSides: morph.targetSides,
        );
        e.add(finalMorph);
        // Clean up the progress component.
        e.remove<AnimationProgressComponent>();
      },
    ));
  }
}
