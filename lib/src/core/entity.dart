import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// A unique identifier for an Entity.
typedef EntityId = int;

/// Represents a single object in the application world.
///
/// --- ARCHITECTURAL FIX: Decoupled from Flutter's ChangeNotifier ---
/// An entity is now a pure data container and does not depend on Flutter's
/// foundation library. It manages its own dirty state, which is the correct
/// approach for a background isolate architecture.
class Entity {
  static int _nextId = 0;
  final EntityId id;
  final Map<Type, Component> _components = {};

  late final NexusWorld world;

  // --- Dirty Checking Mechanism (for rendering) ---
  final Set<Type> _dirtyComponents = {};
  Set<Type> get dirtyComponents => Set.unmodifiable(_dirtyComponents);
  void clearDirty() => _dirtyComponents.clear();

  // --- NEW: Method for the framework to mark all components as dirty for hydration ---
  void markAllComponentsAsDirty() {
    for (final component in _components.values) {
      _dirtyComponents.add(component.runtimeType);
    }
  }

  Entity() : id = _nextId++;

  void setWorld(NexusWorld world) {
    this.world = world;
  }

  void add<T extends Component>(T component, {bool forceNotify = false}) {
    final existingComponent = _components[T];
    world.notifyComponentChange(this, existingComponent, component);

    if (forceNotify ||
        identical(existingComponent, component) ||
        (existingComponent != null && existingComponent != component) ||
        existingComponent == null) {
      _components[T] = component;
      _dirtyComponents.add(T);
    }
  }

  void addComponents(List<Component> components) {
    for (final component in components) {
      final type = component.runtimeType;
      final existingComponent = _components[type];
      world.notifyComponentChange(this, existingComponent, component);

      if (identical(existingComponent, component) ||
          (existingComponent != null && existingComponent != component) ||
          existingComponent == null) {
        _components[type] = component;
        _dirtyComponents.add(type);
      }
    }
  }

  T? remove<T extends Component>() {
    final removed = _components.remove(T) as T?;
    if (removed != null) {
      world.notifyComponentChange(this, removed, null);
      // Mark as dirty to signal removal to the UI.
      _dirtyComponents.add(T);
    }
    return removed;
  }

  Component? removeByType(Type componentType) {
    final removed = _components.remove(componentType);
    if (removed != null) {
      world.notifyComponentChange(this, removed, null);
      // Mark as dirty to signal removal to the UI.
      _dirtyComponents.add(componentType);
    }
    return removed;
  }

  T? get<T extends Component>() => _components[T] as T?;
  Component? getByType(Type componentType) => _components[componentType];
  bool has<T extends Component>() => _components.containsKey(T);
  Iterable<Component> get allComponents => _components.values;

  @override
  String toString() {
    return 'Entity($id, components: ${_components.keys.map((t) => t.toString()).toList()})';
  }

  // --- NEW: Since we removed ChangeNotifier, we need a manual dispose method. ---
  void dispose() {
    _components.clear();
    _dirtyComponents.clear();
  }
}
