import 'package:flutter/gestures.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/clickable_component.dart';
import 'package:nexus/src/components/position_component.dart';

/// A system that processes user tap input.
///
/// This system listens for tap events and checks if the tap occurred within
/// the bounds of any entity that has `ClickableComponent` and `PositionComponent`.
/// If a match is found, it executes the `onTap` callback of the component.
///
/// The `handleTapDown` method should be connected to a `GestureDetector` in
/// the Flutter widget tree.
class InputSystem extends System {
  InputSystem() : super([PositionComponent, ClickableComponent]);

  /// This system is event-driven, so the update loop is not used for input logic.
  @override
  void update(Entity entity, double dt) {
    // Input is handled by the handleTapDown method.
  }

  /// Handles a tap event from a `GestureDetector`.
  ///
  /// Iterates through all clickable entities and checks for collision with the
  /// tap position. If an entity is tapped, its `onTap` callback is invoked.
  void handleTapDown(TapDownDetails details) {
    final tapPosition = details.localPosition;

    // Iterate in reverse to prioritize entities rendered on top.
    final clickableEntities = world.entities.values
        .where((e) => e.hasAll(componentTypes))
        .toList()
        .reversed;

    for (final entity in clickableEntities) {
      final pos = entity.get<PositionComponent>()!;
      final clickable = entity.get<ClickableComponent>()!;

      final entityRect = Rect.fromLTWH(pos.x, pos.y, pos.width, pos.height);

      if (entityRect.contains(tapPosition)) {
        clickable.onTap(entity);
        // Stop after the first hit to prevent tapping through multiple entities.
        break;
      }
    }
  }
}
