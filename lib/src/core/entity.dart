import 'package:flutter/foundation.dart';
import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// A unique identifier for an Entity.
typedef EntityId = int;

/// Represents a single object in the application world.
///
/// --- NEW ARCHITECTURE ---
/// An entity now holds a reference to the world it belongs to. This allows it
/// to notify the world whenever its components change, enabling the new
/// reactive system architecture.
class Entity extends ChangeNotifier {
  static int _nextId = 0;
  final EntityId id;
  final Map<Type, Component> _components = {};

  /// --- NEW: A reference to the world. ---
  late final NexusWorld world;

  // --- Dirty Checking Mechanism (for rendering) ---
  final Set<Type> _dirtyComponents = {};
  Set<Type> get dirtyComponents => Set.unmodifiable(_dirtyComponents);
  void clearDirty() => _dirtyComponents.clear();

  Entity() : id = _nextId++;

  /// Internal method to assign the world to the entity.
  void setWorld(NexusWorld world) {
    this.world = world;
  }

  /// --- MODIFIED: Now notifies the world of component changes. ---
  void add<T extends Component>(T component, {bool forceNotify = false}) {
    final existingComponent = _components[T];

    // --- NEW: Notify the reactive systems BEFORE the component is actually added ---
    // This allows systems to react to the change based on the old and new state.
    world.notifyComponentChange(this, existingComponent, component);

    if (forceNotify) {
      _components[T] = component;
      _dirtyComponents.add(T);
      notifyListeners();
      return;
    }

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

  void addComponents(List<Component> components) {
    bool hasChanged = false;
    for (final component in components) {
      final type = component.runtimeType;
      final existingComponent = _components[type];

      // --- NEW: Notification for reactive systems ---
      world.notifyComponentChange(this, existingComponent, component);

      if (identical(existingComponent, component)) {
        _dirtyComponents.add(type);
        hasChanged = true;
        continue;
      }

      if (existingComponent != null && existingComponent == component) {
        continue;
      }

      _components[type] = component;
      _dirtyComponents.add(type);
      hasChanged = true;
    }
    if (hasChanged) {
      notifyListeners();
    }
  }

  /// --- MODIFIED: Now notifies the world of component removal. ---
  T? remove<T extends Component>() {
    final removed = _components.remove(T) as T?;
    if (removed != null) {
      // --- NEW: Notify reactive systems of the removal ---
      // --- FIX: Removed the explicit generic type <T> which is no longer needed. ---
      world.notifyComponentChange(this, removed, null);
      notifyListeners();
    }
    return removed;
  }

  /// --- MODIFIED: Now notifies the world of component removal. ---
  Component? removeByType(Type componentType) {
    final removed = _components.remove(componentType);
    if (removed != null) {
      // --- NEW: Notify reactive systems of the removal ---
      // --- FIX: This call now works correctly due to the non-generic notifyComponentChange. ---
      world.notifyComponentChange(this, removed, null);
      notifyListeners();
    }
    return removed;
  }

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
