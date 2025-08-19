import 'package:nexus/src/core/component.dart';

/// A unique identifier for an Entity.
typedef EntityId = int;

/// Represents a single object in the application world.
///
/// An Entity is essentially a container for a collection of [Component]s.
/// It has no data or logic of its own, other than a unique ID.
class Entity {
  static int _nextId = 0;
  final EntityId id;
  final Map<Type, Component> _components = {};

  /// A callback that is triggered when a component is added or removed.
  /// The `NexusWorld` uses this to notify the UI.
  void Function()? onComponentChanged;

  Entity() : id = _nextId++;

  /// Adds a component to the entity and notifies listeners of the change.
  void add<T extends Component>(T component) {
    _components[T] = component;
    onComponentChanged?.call();
  }

  /// Removes a component and notifies listeners of the change.
  T? remove<T extends Component>() {
    final removed = _components.remove(T) as T?;
    if (removed != null) {
      onComponentChanged?.call();
    }
    return removed;
  }

  T? get<T extends Component>() {
    return _components[T] as T?;
  }

  bool has<T extends Component>() {
    return _components.containsKey(T);
  }

  Iterable<Component> get allComponents => _components.values;

  bool hasAll(List<Type> componentTypes) {
    return componentTypes.every((type) => _components.containsKey(type));
  }

  @override
  String toString() {
    return 'Entity($id, components: ${_components.keys.map((t) => t.toString().split('.').last).toList()})';
  }
}
