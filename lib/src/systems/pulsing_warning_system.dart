import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';

/// A system that applies and removes a pulsing animation to any entity with a "warning" tag.
///
/// This system is the single source of truth for the warning animation behavior.
/// It watches for the 'warning' tag and manages the lifecycle of the
/// associated AnimationComponent.
class PulsingWarningSystem extends System {
  // A private tag to mark entities that this system is currently animating.
  static const _pulsingMarkerTag = 'system_is_pulsing';

  @override
  bool matches(Entity entity) {
    // This system is interested in any entity that can be tagged and positioned.
    return entity.has<TagsComponent>() && entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final tags = entity.get<TagsComponent>()!;
    final isWarning = tags.hasTag('warning');
    final isPulsing = tags.hasTag(_pulsingMarkerTag);

    // Condition to ADD the animation:
    // The entity is in a warning state, but is not yet pulsing.
    // We also check that no other animation is currently running to avoid conflicts.
    if (isWarning && !isPulsing && !entity.has<AnimationComponent>()) {
      tags.add(_pulsingMarkerTag);
      entity.add(_createPulsingAnimation());
      entity.add(tags);
    }
    // Condition to REMOVE the animation:
    // The entity is no longer in a warning state, but is still marked as pulsing.
    else if (!isWarning && isPulsing) {
      tags.remove(_pulsingMarkerTag);
      entity.remove<AnimationComponent>();
      // Reset scale to 1 in case the animation was stopped mid-pulse.
      final pos = entity.get<PositionComponent>()!;
      pos.scale = 1.0;
      entity.add(pos);
      entity.add(tags);
    }
  }

  AnimationComponent _createPulsingAnimation() {
    return AnimationComponent(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      repeat: true,
      removeOnComplete: false,
      onUpdate: (entity, value) {
        final double scaleValue;
        if (value < 0.5) {
          // First half: scale up
          scaleValue = 1.0 + (value * 2 * 0.05); // Scale up to 1.05
        } else {
          // Second half: scale down
          scaleValue = 1.05 - ((value - 0.5) * 2 * 0.05); // Scale back to 1.0
        }
        final pos = entity.get<PositionComponent>()!;
        pos.scale = scaleValue;
        entity.add(pos);
      },
    );
  }
}
