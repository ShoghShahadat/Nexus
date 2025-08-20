import 'dart:convert';
import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A function signature for a factory that creates a [Component] from a JSON map.
typedef ComponentFactory = Component Function(Map<String, dynamic> json);

/// A registry for mapping component type names to their deserialization factories.
///
/// This is essential for the [WorldSerializer] to dynamically reconstruct
/// components of various types from a saved JSON state.
class ComponentFactoryRegistry {
  final Map<String, ComponentFactory> _factories = {};

  /// Registers a component factory for a given type [T].
  ///
  /// This must be called for every [SerializableComponent] type before
  /// attempting to deserialize a world state containing that component.
  void register<T extends Component>(ComponentFactory factory) {
    _factories[T.toString()] = factory;
  }

  /// Creates a component instance from a JSON map using the registered factory.
  /// Throws an exception if no factory is registered for the given type name.
  Component create(String typeName, Map<String, dynamic> json) {
    final factory = _factories[typeName];
    if (factory == null) {
      throw Exception('No factory registered for component type "$typeName". '
          'Ensure you call ComponentFactoryRegistry.register<$typeName>() '
          'before deserialization.');
    }
    return factory(json);
  }
}
