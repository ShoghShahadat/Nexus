import 'package:nexus/nexus.dart';

/// A system that manages the lifecycle of entities.
///
/// It listens for entities with a [LifecycleComponent] and executes the
/// provided `onInit` and `onDispose` callbacks at the appropriate times.
///
/// --- RE-ARCHITECTED as an UpdateSystem ---
/// This system needs to know about entity addition/removal, which is a feature
/// of the UpdateSystem class in the new architecture. Its update loop is empty.
class LifecycleSystem extends UpdateSystem {
  @override
  bool matches(Entity entity) {
    return entity.has<LifecycleComponent>();
  }

  /// The update loop is not used by this system as it is purely event-driven.
  @override
  void update(Entity entity, double dt) {}

  @override
  void onEntityAdded(Entity entity) {
    // We can safely use `!` because `matches` guarantees the component exists.
    final lifecycle = entity.get<LifecycleComponent>()!;
    lifecycle.onInit?.call(entity);
  }

  @override
  void onEntityRemoved(Entity entity) {
    // We can safely use `!` because `matches` guarantees the component exists.
    final lifecycle = entity.get<LifecycleComponent>()!;
    lifecycle.onDispose?.call(entity);
  }
}
