import 'package:nexus/src/core/component.dart';

/// A unique identifier for an Entity.
typedef EntityId = int;

/// Represents a single object in the application world.
///
/// An Entity is essentially a container for a collection of [Component]s.
/// It has no data or logic of its own, other than a unique ID.
/// The combination of components attached to an entity defines what it is
/// and what it can do.
class Entity {
  /// A static counter to ensure each entity has a unique ID.
  static int _nextId = 0;

  /// The unique identifier for this entity.
  final EntityId id;

  /// The collection of components attached to this entity.
  final Map<Type, Component> _components = {};

  /// Creates a new entity with a unique ID.
  Entity() : id = _nextId++;

  /// Adds a component to the entity.
  /// If a component of the same type already exists, it will be replaced.
  void add<T extends Component>(T component) {
    _components[T] = component;
  }

  /// Removes a component of a specific type from the entity.
  /// Returns the removed component, or null if it didn't exist.
  T? remove<T extends Component>() {
    return _components.remove(T) as T?;
  }

  /// Retrieves a component of a specific type from the entity.
  /// Returns null if the entity does not have a component of this type.
  T? get<T extends Component>() {
    return _components[T] as T?;
  }

  /// Checks if the entity has a component of a specific type.
  bool has<T extends Component>() {
    return _components.containsKey(T);
  }

  /// Returns an iterable of all components attached to this entity.
  /// Useful for systems that need to manually inspect components.
  Iterable<Component> get allComponents => _components.values;

  /// Checks if the entity has all the specified component types.
  /// Note: This performs an exact type match and may not work as expected
  /// with generic components like BlocComponent.
  bool hasAll(List<Type> componentTypes) {
    return componentTypes.every((type) => _components.containsKey(type));
  }

  @override
  String toString() {
    return 'Entity($id, components: ${_components.keys.map((t) => t.toString().split('.').last).toList()})';
  }
}
