import 'package:nexus/nexus.dart';

/// A system that processes [AnimationComponent]s to drive animations.
///
/// --- RE-ARCHITECTED as an UpdateSystem ---
/// Animation is time-dependent and must run every frame.
class AnimationSystem extends UpdateSystem {
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
        Future.microtask(() {
          if (world.entities.containsKey(entity.id)) {
            entity.remove<AnimationComponent>();
          }
        });
      }
    }
  }
}
