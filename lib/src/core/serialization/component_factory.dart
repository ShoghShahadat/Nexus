import 'package:nexus/nexus.dart';

// This file is now fully self-contained within the library.

/// A function signature for a factory that creates a [Component] from a JSON map.
typedef ComponentFactory = Component Function(Map<String, dynamic> json);

/// A registry for mapping component type names to their deserialization factories.
class ComponentFactoryRegistry {
  final Map<String, ComponentFactory> _factories = {};

  static final ComponentFactoryRegistry I =
      ComponentFactoryRegistry._internal();

  ComponentFactoryRegistry._internal();

  void register(String typeName, ComponentFactory factory) {
    _factories[typeName] = factory;
  }

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
  // --- NEW: Register the new SpawnerLinkComponent ---
  ComponentFactoryRegistry.I.register(
      'SpawnerLinkComponent', (json) => SpawnerLinkComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'ChildrenComponent', (json) => ChildrenComponent.fromJson(json));
  ComponentFactoryRegistry.I
      .register('HistoryComponent', (json) => HistoryComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('RenderStrategyComponent',
      (json) => RenderStrategyComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'BlackboardComponent', (json) => BlackboardComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'PersistenceComponent', (json) => PersistenceComponent.fromJson(json));
}
