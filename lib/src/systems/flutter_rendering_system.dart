import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/widget_component.dart';

/// A system that renders entities with `WidgetComponent` and `PositionComponent`.
///
/// This system queries for all entities that have a visual representation
/// and a position, then uses a `Stack` widget to draw them on the screen.
/// It acts as the main rendering engine for the UI within a Nexus world.
///
/// Note: This system does not perform updates in the `update` loop. Instead,
/// it provides a `build` method that should be called from the `NexusWidget`'s
/// builder function to construct the widget tree.
class FlutterRenderingSystem extends System {
  FlutterRenderingSystem() : super([PositionComponent, WidgetComponent]);

  /// This system's logic is primarily in the `build` method, not the update loop.
  @override
  void update(Entity entity, double dt) {
    // Rendering is handled by the build method.
  }

  /// Builds the widget representation of the current state of the world.
  ///
  /// This method should be called from your `NexusWidget.builder`. It iterates
  /// through all renderable entities and positions them in a `Stack`.
  Widget build(BuildContext context) {
    final renderableEntities =
        world.entities.values.where((e) => e.hasAll(componentTypes)).toList();

    return Stack(
      children: renderableEntities.map((entity) {
        final pos = entity.get<PositionComponent>()!;
        final widgetComp = entity.get<WidgetComponent>()!;

        return Positioned(
          left: pos.x,
          top: pos.y,
          width: pos.width,
          height: pos.height,
          child: widgetComp.widget,
        );
      }).toList(),
    );
  }
}
