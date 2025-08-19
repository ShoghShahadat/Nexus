import 'package:flutter/foundation.dart';
import 'package:nexus/src/core/component.dart';

/// A unique identifier for an Entity.
typedef EntityId = int;

/// Represents a single object in the application world.
///
/// An Entity is essentially a container for a collection of [Component]s.
/// It extends [ChangeNotifier] so that widgets can listen to changes
/// on a specific entity and rebuild atomically.
class Entity extends ChangeNotifier {
  static int _nextId = 0;
  final EntityId id;
  // Reverting to a Map<Type, Component> is the most performant and
  // type-safe approach when systems are strongly typed.
  final Map<Type, Component> _components = {};

  Entity() : id = _nextId++;

  /// Adds a component to the entity and notifies listeners of the change.
  /// If a component of the same type already exists, it will be replaced.
  void add<T extends Component>(T component) {
    _components[T] = component;
    notifyListeners();
  }

  /// Removes a component and notifies listeners of the change.
  T? remove<T extends Component>() {
    final removed = _components.remove(T) as T?;
    if (removed != null) {
      notifyListeners();
    }
    return removed;
  }

  /// Retrieves a component of a specific type from the entity.
  /// This is now a direct and fast map lookup.
  T? get<T extends Component>() {
    return _components[T] as T?;
  }

  /// Checks if the entity has a component of a specific type.
  bool has<T extends Component>() {
    return _components.containsKey(T);
  }

  /// An iterable of all components attached to this entity.
  Iterable<Component> get allComponents => _components.values;

  @override
  String toString() {
    return 'Entity($id, components: ${_components.keys.map((t) => t.toString()).toList()})';
  }
}
