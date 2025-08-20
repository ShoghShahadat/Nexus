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

  /// Adds a component to the entity and notifies listeners.
  ///
  /// This method is optimized to prevent unnecessary notifications.
  /// - If the exact same component instance is passed, it assumes the component
  ///   was mutated and always notifies listeners.
  /// - If a new component instance is passed, it uses value-based equality
  ///   to check if the data has actually changed before notifying.
  void add<T extends Component>(T component) {
    final existingComponent = _components[T];

    // If it's the exact same instance, we assume it was mutated internally
    // and a notification is desired.
    if (identical(existingComponent, component)) {
      notifyListeners();
      return;
    }

    // If it's a new instance, but its value is the same as the existing one,
    // do nothing to prevent redundant notifications and UI rebuilds.
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
