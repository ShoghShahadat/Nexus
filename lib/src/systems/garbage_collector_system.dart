import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/lifecycle_policy_component.dart';

/// A background system that periodically checks for and removes entities
/// that meet their destruction condition, preventing logical memory leaks.
class GarbageCollectorSystem extends System {
  double _timer = 0.0;
  final double _checkInterval; // How often to run the check, in seconds.
  final bool enabled; // --- NEW: Flag to enable/disable the GC ---

  GarbageCollectorSystem({
    double checkInterval = 2.0,
    this.enabled =
        true, // --- NEW: Enabled by default for backward compatibility ---
  }) : _checkInterval = checkInterval;

  @override
  bool matches(Entity entity) {
    // This system doesn't operate on entities in the traditional update loop.
    return false;
  }

  @override
  void update(Entity entity, double dt) {
    // The logic is handled in the runGc method.
  }

  /// This method should be called once per frame from a central system.
  void runGc(double dt) {
    // --- NEW: Immediately exit if the system is disabled ---
    if (!enabled) {
      return;
    }

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
