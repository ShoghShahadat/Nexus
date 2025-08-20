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

  // --- Dirty Checking Mechanism ---
  /// A set of component types that have been modified in the current frame.
  final Set<Type> _dirtyComponents = {};
  Set<Type> get dirtyComponents => Set.unmodifiable(_dirtyComponents);
  void clearDirty() => _dirtyComponents.clear();

  Entity() : id = _nextId++;

  /// Adds a component to the entity and notifies listeners.
  void add<T extends Component>(T component) {
    final existingComponent = _components[T];

    if (identical(existingComponent, component)) {
      _dirtyComponents.add(T);
      notifyListeners();
      return;
    }

    if (existingComponent != null && existingComponent == component) {
      return;
    }

    _components[T] = component;
    _dirtyComponents.add(T);
    notifyListeners();
  }

  /// Removes a component of a specific type using generics and notifies listeners.
  T? remove<T extends Component>() {
    final removed = _components.remove(T) as T?;
    if (removed != null) {
      notifyListeners();
    }
    return removed;
  }

  // --- NEW: Method to remove a component by its Type object ---
  /// Removes a component of a specific type using a Type object and notifies listeners.
  Component? removeByType(Type componentType) {
    final removed = _components.remove(componentType);
    if (removed != null) {
      notifyListeners();
    }
    return removed;
  }
  // --- END NEW ---

  /// Retrieves a component of a specific type from the entity using generics.
  T? get<T extends Component>() {
    return _components[T] as T?;
  }

  /// Retrieves a component of a specific type from the entity using a Type object.
  Component? getByType(Type componentType) {
    return _components[componentType];
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
