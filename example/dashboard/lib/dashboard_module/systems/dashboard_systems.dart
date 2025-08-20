import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';

/// Provides all systems related to the dashboard feature.
class DashboardSystemProvider extends SystemProvider {
  @override
  List<System> get systems => [
        EntryAnimationSystem(),
      ];
}

/// A system that creates and manages the entry animations for dashboard elements.
///
/// It looks for entities with an [EntryAnimationComponent] that haven't been
/// animated yet and attaches an [AnimationComponent] to them to create a
/// staggered, delayed fade-in and slide-up effect.
class EntryAnimationSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system targets entities that have an entry animation defined
    // but are not currently being animated by a generic AnimationComponent.
    return entity.has<EntryAnimationComponent>() &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final entryAnim = entity.get<EntryAnimationComponent>()!;
    final pos = entity.get<PositionComponent>();
    if (pos == null) return;

    // Store the original position to animate towards it.
    final originalY = pos.y;
    // Start the animation from a lower position.
    pos.y = originalY + 30.0;
    // Start with zero scale.
    pos.scale = 0.0;
    entity.add(pos);

    // Attach the main AnimationComponent to drive the visual changes.
    entity.add(AnimationComponent(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      autostart: false, // We will start it manually after the delay.
      onUpdate: (e, value) {
        final currentPos = e.get<PositionComponent>()!;
        // Animate Y position from start to original.
        currentPos.y = (originalY + 30.0) - (30.0 * value);
        // Animate scale from 0 to 1.
        currentPos.scale = value;
        e.add(currentPos);
      },
      onComplete: (e) {
        // Clean up by removing the entry animation trigger component.
        e.remove<EntryAnimationComponent>();
      },
    ));

    // Use a delayed future to start the animation after the specified delay.
    Future.delayed(Duration(milliseconds: (entryAnim.delay * 1000).toInt()),
        () {
      // Ensure the entity still exists in the world before trying to animate it.
      if (world.entities.containsKey(entity.id)) {
        entity.get<AnimationComponent>()?.play();
      }
    });
  }
}
