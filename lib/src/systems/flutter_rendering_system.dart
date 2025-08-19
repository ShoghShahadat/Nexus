import 'package:flutter/widgets.dart';
import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/widget_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';
import 'package:nexus/src/flutter/entity_widget_builder.dart';

/// A system that renders entities using a highly optimized approach.
class FlutterRenderingSystem extends System {
  /// Defines that this system is interested in entities that have both
  /// a `PositionComponent` and a `WidgetComponent`.
  @override
  bool matches(Entity entity) {
    return entity.has<PositionComponent>() && entity.has<WidgetComponent>();
  }

  /// The update loop is not used for rendering logic.
  @override
  void update(Entity entity, double dt) {}

  /// Builds the widget representation of the current state of the world.
  Widget build(BuildContext context) {
    final renderableEntities =
        world.entities.values.where((e) => matches(e)).toList();

    return Stack(
      children: renderableEntities.map((entity) {
        // The EntityWidgetBuilder is now the root of each entity's widget tree.
        // This ensures that any component change triggers a rebuild of the
        // entire presentation layer for that entity (Position, Scale, etc.).
        return EntityWidgetBuilder(
          key: ValueKey(entity.id),
          entity: entity,
          builder: (context, entity) {
            // All component data is now read *inside* the builder.
            // This is crucial for the UI to react to changes.
            final pos = entity.get<PositionComponent>()!;
            final widgetComp = entity.get<WidgetComponent>()!;

            return Positioned(
              left: pos.x,
              top: pos.y,
              width: pos.width,
              height: pos.height,
              child: Transform.scale(
                scale: pos.scale,
                // The user-defined widget is now built as a child.
                child: widgetComp.builder(context, entity),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
