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
  // Using a List is more robust for generic types than a Map with Type keys.
  final List<Component> _components = [];

  Entity() : id = _nextId++;

  /// Adds a component to the entity and notifies listeners of the change.
  /// If a component of the same type already exists, it will be replaced.
  void add<T extends Component>(T component) {
    // Remove any existing component of the same type first.
    _components.removeWhere((c) => c is T);
    _components.add(component);
    notifyListeners();
  }

  /// Removes a component and notifies listeners of the change.
  T? remove<T extends Component>() {
    T? found;
    _components.removeWhere((c) {
      if (c is T) {
        found = c;
        return true;
      }
      return false;
    });
    if (found != null) {
      notifyListeners();
    }
    return found;
  }

  /// Retrieves a component of a specific type from the entity.
  /// This method is robust against generic type issues.
  T? get<T extends Component>() {
    for (final comp in _components) {
      if (comp is T) {
        return comp;
      }
    }
    return null;
  }

  /// Checks if the entity has a component of a specific type.
  /// This method is robust against generic type issues.
  bool has<T extends Component>() {
    for (final comp in _components) {
      if (comp is T) {
        return true;
      }
    }
    return false;
  }

  /// An iterable of all components attached to this entity.
  Iterable<Component> get allComponents => _components;

  @override
  String toString() {
    return 'Entity($id, components: ${_components.map((c) => c.runtimeType.toString()).toList()})';
  }
}
