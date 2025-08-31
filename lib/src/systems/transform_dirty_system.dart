import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/global_transform_component.dart';

/// A reactive system that marks entities and their children as "dirty"
/// whenever their local position or parent changes.
class TransformDirtySystem extends ReactiveSystem {
  @override
  Set<Type> get subscribedComponentTypes =>
      {PositionComponent, ParentComponent};

  @override
  void onComponentChanged(
      Entity entity, Component? oldComponent, Component newComponent) {
    _markDirtyRecursive(entity);
  }

  @override
  void onComponentRemoved(Entity entity, Component removedComponent) {
    _markDirtyRecursive(entity);
    // If a parent component is removed, the entity becomes a root.
    // Its old parent's other children are not affected.
  }

  void _markDirtyRecursive(Entity entity) {
    final global =
        entity.get<GlobalTransformComponent>() ?? GlobalTransformComponent();
    if (global.isDirty) return; // Already dirty, no need to proceed

    entity.add(GlobalTransformComponent(
      x: global.x,
      y: global.y,
      scale: global.scale,
      rotation: global.rotation,
      isDirty: true,
    ));

    // Recursively mark all children as dirty as well
    final childrenComp = entity.get<ChildrenComponent>();
    if (childrenComp != null) {
      for (final childId in childrenComp.children) {
        final childEntity = world.entities[childId];
        if (childEntity != null) {
          _markDirtyRecursive(childEntity);
        }
      }
    }
  }
}
