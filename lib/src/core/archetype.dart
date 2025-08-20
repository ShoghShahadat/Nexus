import 'package:nexus/nexus.dart';

/// Represents a reusable template or "prefab" of components.
///
/// An Archetype is a way to define a collection of components that constitute
/// a specific type of entity (e.g., "Animal", "Player", "Enemy").
class Archetype {
  final List<Component> _components;

  /// A set of component types contained within this archetype.
  /// Used by the ArchetypeSystem to know which components to remove when an archetype is deactivated.
  final Set<Type> componentTypes;

  Archetype(this._components)
      : componentTypes = _components.map((c) => c.runtimeType).toSet();

  /// Applies all components from this archetype to the given entity.
  void apply(Entity entity) {
    for (final component in _components) {
      entity.add(component);
    }
  }
}
