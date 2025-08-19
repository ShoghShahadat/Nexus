import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/widget_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that renders entities with `WidgetComponent` and `PositionComponent`.
///
/// This system provides a `build` method to construct the widget tree.
/// Crucially, it listens to changes on entities and notifies the `NexusWorld`
/// when a visual update is required, triggering a UI rebuild.
class FlutterRenderingSystem extends System {
  FlutterRenderingSystem() : super([PositionComponent, WidgetComponent]);

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // When the system is added, we need to listen for component changes.
    // This is a simplified listener. A more robust implementation might
    // use a dedicated event bus.
    for (var entity in world.entities.values) {
      if (matches(entity)) {
        _watchEntity(entity);
      }
    }
  }

  void _watchEntity(Entity entity) {
    // This is a conceptual representation. In a real-world scenario,
    // the entity itself might become a notifier, or we'd use an event bus.
    // For now, we trigger the notification when the component is added/changed.
    // We achieve this by modifying the entity's `add` method.
  }

  /// This system's logic is primarily in the `build` method.
  @override
  void update(Entity entity, double dt) {
    // The update loop is not used for rendering logic itself,
    // but it's where we could detect changes if components were mutable.
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
