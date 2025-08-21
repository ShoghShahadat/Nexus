import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/lifecycle_policy_component.dart';

/// A background system that periodically checks for and removes entities
/// that meet their destruction condition, preventing logical memory leaks.
class GarbageCollectorSystem extends System {
  double _timer = 0.0;
  final double _checkInterval; // How often to run the check, in seconds.

  GarbageCollectorSystem({double checkInterval = 2.0})
      : _checkInterval = checkInterval;

  @override
  bool matches(Entity entity) {
    // This system doesn't operate on entities in the traditional update loop.
    // It iterates over all entities manually.
    return false;
  }

  @override
  void update(Entity entity, double dt) {
    // The logic is handled in the root entity's update or a separate timer.
    // For simplicity, we'll tie it to the root entity's update cycle.
  }

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // We can use a simple timer tied to the game loop.
    // This system will be driven by the update of the root entity.
    // A more advanced implementation could use its own independent timer.
  }

  /// This method should be called once per frame from a central system
  /// or tied to the root entity's update.
  void runGc(double dt) {
    _timer += dt;
    if (_timer < _checkInterval) {
      return;
    }
    _timer = 0.0;

    final entitiesToCheck = List<Entity>.from(world.entities.values);
    final entitiesToRemove = <EntityId>[];

    for (final entity in entitiesToCheck) {
      final policy = entity.get<LifecyclePolicyComponent>();

      if (policy == null) {
        // Ignore the root entity as it's the foundation.
        if (entity.id != world.rootEntity.id) {
          debugPrint(
              '[GarbageCollector] WARNING: Entity ID ${entity.id} is missing a LifecyclePolicyComponent. This can lead to memory leaks.');
        }
        continue;
      }

      if (!policy.isPersistent && policy.destructionCondition(entity)) {
        entitiesToRemove.add(entity.id);
      }
    }

    if (entitiesToRemove.isNotEmpty) {
      debugPrint(
          '[GarbageCollector] Purging ${entitiesToRemove.length} entities.');
      for (final id in entitiesToRemove) {
        world.removeEntity(id);
      }
    }
  }
}
