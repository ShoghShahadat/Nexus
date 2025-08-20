import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/tags_component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';
import 'package:nexus/src/components/animation_progress_component.dart';
import 'package:nexus/src/components/counter_state_component.dart';
import 'package:nexus/src/components/custom_widget_component.dart';
import 'package:nexus/src/components/morphing_component.dart';
import 'package:nexus/src/components/shape_path_component.dart';

/// A function signature for a factory that creates a [Component] from a JSON map.
typedef ComponentFactory = Component Function(Map<String, dynamic> json);

/// A registry for mapping component type names to their deserialization factories.
///
/// This is essential for the UI thread to dynamically reconstruct
/// components of various types from a RenderPacket.
class ComponentFactoryRegistry {
  final Map<String, ComponentFactory> _factories = {};

  /// A globally accessible singleton instance.
  static final ComponentFactoryRegistry I =
      ComponentFactoryRegistry._internal();

  ComponentFactoryRegistry._internal();

  /// Registers a component factory for a given type name.
  void register(String typeName, ComponentFactory factory) {
    _factories[typeName] = factory;
  }

  /// Creates a component instance from a JSON map using the registered factory.
  /// Throws an exception if no factory is registered for the given type name.
  Component create(String typeName, Map<String, dynamic> json) {
    final factory = _factories[typeName];
    if (factory == null) {
      throw Exception('No factory registered for component type "$typeName". '
          'Ensure you call ComponentFactoryRegistry.I.register() '
          'before deserialization.');
    }
    return factory(json);
  }
}

/// A helper function to register all default serializable components.
/// This should be called once at application startup.
void registerCoreComponents() {
  // Using string literals for type names is a robust way to avoid compiler issues.
  ComponentFactoryRegistry.I.register(
      'PositionComponent', (json) => PositionComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('TagsComponent', (json) => TagsComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('AnimationProgressComponent',
      (json) => AnimationProgressComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'CounterStateComponent', (json) => CounterStateComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('MorphingLogicComponent',
      (json) => MorphingLogicComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'ShapePathComponent', (json) => ShapePathComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'CustomWidgetComponent', (json) => CustomWidgetComponent.fromJson(json));
}
