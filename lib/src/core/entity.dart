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
  final Map<Type, Component> _components = {};

  Entity() : id = _nextId++;

  /// Adds a component to the entity and notifies listeners ONLY if the new
  /// component is different from the existing one of the same type.
  ///
  /// This intelligent update mechanism prevents unnecessary UI rebuilds by
  /// performing a value-based equality check before notifying listeners.
  void add<T extends Component>(T component) {
    final existingComponent = _components[T];

    // Optimization: If a component of the same type exists and is equal to
    // the new one, do nothing to avoid redundant notifications.
    if (existingComponent != null && existingComponent == component) {
      return;
    }

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
