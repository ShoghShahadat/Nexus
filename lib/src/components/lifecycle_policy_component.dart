import 'package:nexus/nexus.dart';

/// A component that defines the lifecycle rules for an entity, helping to
/// prevent memory leaks by ensuring every entity has a defined end-of-life.
///
/// This component should be added to almost every entity. The GarbageCollectorSystem
/// will warn if an entity (besides the root) is missing this component.
class LifecyclePolicyComponent extends Component {
  /// If true, this entity is considered persistent and will never be garbage
  /// collected. Suitable for player entities, UI managers, or spawners.
  final bool isPersistent;

  /// A function that returns `true` if the entity should be destroyed.
  /// This is ignored if `isPersistent` is true.
  /// Example: `(entity) => entity.get<HealthComponent>()?.currentHealth <= 0`
  final bool Function(Entity entity) destructionCondition;

  LifecyclePolicyComponent({
    this.isPersistent = false,
    // Provide a default condition that is always false to avoid null checks.
    // The developer is expected to override this for non-persistent entities.
    bool Function(Entity entity)? destructionCondition,
  }) : destructionCondition = destructionCondition ?? ((e) => false);

  // This component contains a function and should not be serialized.
  @override
  List<Object?> get props => [isPersistent];
}
