import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:nexus/src/components/clickable_component.dart';
import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that processes user tap input.
class InputSystem extends System {
  /// Defines that this system is interested in entities that have both
  /// a `PositionComponent` and a `ClickableComponent`.
  @override
  bool matches(Entity entity) {
    return entity.has<PositionComponent>() && entity.has<ClickableComponent>();
  }

  /// This system is event-driven, so the update loop is not used.
  @override
  void update(Entity entity, double dt) {}

  /// Handles a tap event from a `GestureDetector`.
  void handleTapDown(TapDownDetails details) {
    final tapPosition = details.localPosition;

    final clickableEntities =
        world.entities.values.where((e) => matches(e)).toList().reversed;

    for (final entity in clickableEntities) {
      // We can safely use `!` because `matches` guarantees they exist.
      final pos = entity.get<PositionComponent>()!;
      final clickable = entity.get<ClickableComponent>()!;

      final entityRect = Rect.fromLTWH(pos.x, pos.y, pos.width, pos.height);

      if (entityRect.contains(tapPosition)) {
        clickable.onTap(entity);
        break;
      }
    }
  }
}
