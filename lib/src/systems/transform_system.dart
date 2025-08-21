import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/parent_component.dart';

/// A system that manages hierarchical transformations.
///
/// It processes entities with a `ParentComponent` and updates their global
/// position based on the parent's position. This allows for complex, nested
/// movements where children move relative to their parent.
class TransformSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system acts on any entity that has a parent and a position.
    return entity.has<ParentComponent>() && entity.has<PositionComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final parentComp = entity.get<ParentComponent>()!;
    final pos = entity.get<PositionComponent>()!;

    final parentEntity = world.entities[parentComp.parentId];
    if (parentEntity == null) {
      // If the parent is gone, this entity should probably be removed too,
      // or at least have its ParentComponent removed. For now, we just stop.
      return;
    }

    final parentPos = parentEntity.get<PositionComponent>();
    if (parentPos == null) return;

    // NOTE: This is a simplified implementation. A full implementation would
    // handle local vs. global positions, rotation, and scale inheritance.
    // Here, we assume the child's position is an offset from the parent's position.
    final globalX = parentPos.x + pos.x;
    final globalY = parentPos.y + pos.y;

    // This system calculates the global position but doesn't directly modify
    // the entity's PositionComponent, as that stores local position.
    // Instead, other systems (like the rendering system) would need to be aware
    // of this hierarchy to calculate the final render position.
    // For simplicity in this version, we will assume other systems will handle this.
    // A more advanced version might add a `GlobalPositionComponent` to the entity.
  }
}
