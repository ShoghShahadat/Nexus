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
    final anim = entity.get<AnimationComponent>()!;

    if (!anim.isPlaying || anim.isFinished) {
      return;
    }

    anim.update(dt);
    anim.onUpdate(entity, anim.curvedValue);

    if (anim.isFinished) {
      anim.onComplete?.call(entity);

      if (anim.repeat) {
        anim.reset();
      } else if (anim.removeOnComplete) {
        // --- FIX: Prevent "use after free" error ---
        // Schedule a microtask to remove the component, but first, check
        // if the entity still exists in the world. This is crucial because the
        // onComplete callback might have already removed and disposed the entity.
        Future.microtask(() {
          if (world.entities.containsKey(entity.id)) {
            entity.remove<AnimationComponent>();
          }
        });
      }
    }
  }
}
