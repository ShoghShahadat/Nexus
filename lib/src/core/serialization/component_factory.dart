import 'package:nexus/nexus.dart';

// This file is now fully self-contained within the library.

/// A function signature for a factory that creates a [Component] from a JSON map.
typedef ComponentFactory = Component Function(Map<String, dynamic> json);

/// A type alias for a map of component type names to their factories.
typedef ComponentRegistryMap = Map<String, ComponentFactory>;

/// A registry for mapping component type names to their deserialization factories.
class ComponentFactoryRegistry {
  final Map<String, ComponentFactory> _factories = {};

  static final ComponentFactoryRegistry I =
      ComponentFactoryRegistry._internal();

  ComponentFactoryRegistry._internal();

  /// Registers a single component factory.
  void register(String typeName, ComponentFactory factory) {
    _factories[typeName] = factory;
  }

  /// Registers multiple component factories from a map.
  void registerAll(ComponentRegistryMap factories) {
    _factories.addAll(factories);
  }

  Component create(String typeName, Map<String, dynamic> json) {
    final factory = _factories[typeName];
    if (factory == null) {
      throw Exception('No factory registered for component type "$typeName". '
          'Ensure you call ComponentFactoryRegistry.I.register() or registerAll() '
          'for all custom serializable components at the start of your application.');
    }
    return factory(json);
  }
}

/// A helper function to register all default serializable components from the core library.
void registerCoreComponents() {
  final coreComponents = <String, ComponentFactory>{
    // Core Components
    'PositionComponent': (json) => PositionComponent.fromJson(json),
    'TagsComponent': (json) => TagsComponent.fromJson(json),
    'AnimationProgressComponent': (json) =>
        AnimationProgressComponent.fromJson(json),
    'CounterStateComponent': (json) => CounterStateComponent.fromJson(json),
    'MorphingLogicComponent': (json) => MorphingLogicComponent.fromJson(json),
    'ShapePathComponent': (json) => ShapePathComponent.fromJson(json),
    'CustomWidgetComponent': (json) => CustomWidgetComponent.fromJson(json),
    'ParticleComponent': (json) => ParticleComponent.fromJson(json),
    'AttractorComponent': (json) => AttractorComponent.fromJson(json),
    'VelocityComponent': (json) => VelocityComponent.fromJson(json),
    'ParticleSpawnerComponent': (json) =>
        ParticleSpawnerComponent.fromJson(json),
    'SpawnerLinkComponent': (json) => SpawnerLinkComponent.fromJson(json),
    'ChildrenComponent': (json) => ChildrenComponent.fromJson(json),
    'HistoryComponent': (json) => HistoryComponent.fromJson(json),
    'RenderStrategyComponent': (json) => RenderStrategyComponent.fromJson(json),
    'BlackboardComponent': (json) => BlackboardComponent.fromJson(json),
    'PersistenceComponent': (json) => PersistenceComponent.fromJson(json),
    'ApiStatusComponent': (json) => ApiStatusComponent.fromJson(json),
    'AppLifecycleComponent': (json) => AppLifecycleComponent.fromJson(json),
    'WebSocketStateComponent': (json) => WebSocketStateComponent.fromJson(json),
    'ThemeComponent': (json) => ThemeComponent.fromJson(json),
    'StyleableComponent': (json) => StyleableComponent.fromJson(json),
    'ScreenInfoComponent': (json) => ScreenInfoComponent.fromJson(json),
    'CategoryComponent': (json) => CategoryComponent.fromJson(json),
    'ParentComponent': (json) => ParentComponent.fromJson(json),
    'LinkComponent': (json) => LinkComponent.fromJson(json),

    // Gameplay Components
    'TargetingComponent': (json) => TargetingComponent.fromJson(json),
    'CollisionComponent': (json) => CollisionComponent.fromJson(json),
    'HealthComponent': (json) => HealthComponent.fromJson(json),
    'DamageComponent': (json) => DamageComponent.fromJson(json),
    'InputFocusComponent': (json) => InputFocusComponent.fromJson(json),
    'KeyboardInputComponent': (json) => KeyboardInputComponent.fromJson(json),

    // List Components
    'ListComponent': (json) => ListComponent.fromJson(json),
    'ListStateComponent': (json) => ListStateComponent.fromJson(json),
    'AnimateOutComponent': (json) => AnimateOutComponent.fromJson(json),
  };

  ComponentFactoryRegistry.I.registerAll(coreComponents);
}
