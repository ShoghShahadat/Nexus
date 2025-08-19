import 'package:nexus/src/components/animation_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that processes [AnimationComponent]s to drive animations.
///
/// In each frame, this system updates the elapsed time for all active
/// animations, calculates the new value based on the duration and curve,
/// and applies it by calling the component's `onUpdate` callback.
class AnimationSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // We can safely use `!` because `matches` guarantees the component exists.
    final anim = entity.get<AnimationComponent>()!;

    if (!anim.isPlaying || anim.isFinished) {
      return;
    }

    // Update internal state
    anim.update(dt);

    // Apply the new value
    anim.onUpdate(entity, anim.curvedValue);

    // Handle completion
    if (anim.isFinished) {
      anim.onComplete?.call(entity);

      if (anim.repeat) {
        anim.reset();
      } else if (anim.removeOnComplete) {
        // Use a post-frame callback to avoid concurrent modification issues
        // while iterating over components in the entity.
        Future.microtask(() => entity.remove<AnimationComponent>());
      }
    }
  }
}
