import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/components/position_component.dart';
import 'package:nexus/src/components/tags_component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';
import 'package:nexus/src/components/animation_progress_component.dart';
import 'package:nexus/src/components/attractor_component.dart';
import 'package:nexus/src/components/counter_state_component.dart';
import 'package:nexus/src/components/custom_widget_component.dart';
import 'package:nexus/src/components/morphing_component.dart';
import 'package:nexus/src/components/particle_component.dart';
import 'package:nexus/src/components/shape_path_component.dart';
import 'package:nexus/src/components/spawner_component.dart';
import 'package:nexus/src/components/velocity_component.dart';

// FIX: Removed dependency on example project. This file is now self-contained.

/// A function signature for a factory that creates a [Component] from a JSON map.
typedef ComponentFactory = Component Function(Map<String, dynamic> json);

/// A registry for mapping component type names to their deserialization factories.
/// This registry is now populated by the application code, not the library.
class ComponentFactoryRegistry {
  final Map<String, ComponentFactory> _factories = {};

  static final ComponentFactoryRegistry I =
      ComponentFactoryRegistry._internal();

  ComponentFactoryRegistry._internal();

  /// Registers a component factory. This should be called from the application's setup code.
  void register(String typeName, ComponentFactory factory) {
    _factories[typeName] = factory;
  }

  /// Creates a component instance from JSON using a registered factory.
  Component create(String typeName, Map<String, dynamic> json) {
    final factory = _factories[typeName];
    if (factory == null) {
      throw Exception('No factory registered for component type "$typeName". '
          'Ensure you call ComponentFactoryRegistry.I.register() for all custom '
          'serializable components at the start of your application.');
    }
    return factory(json);
  }
}

/// A helper function to register all default serializable components from the core library.
/// This should be called by the application at startup.
void registerCoreComponents() {
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
  ComponentFactoryRegistry.I.register(
      'ParticleComponent', (json) => ParticleComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'AttractorComponent', (json) => AttractorComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'VelocityComponent', (json) => VelocityComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('SpawnerComponent', (json) => SpawnerComponent.fromJson(json));
}

// FIX: Removed the dashboard-specific registration function.
// This logic now belongs in the example application code.
