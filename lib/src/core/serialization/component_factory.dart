import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/dom_element_component.dart';
import 'package:nexus/src/components/global_transform_component.dart';
import 'package:nexus/src/components/stylesheet_component.dart';

/// A function signature for a factory that creates a [Component] from a JSON map.
typedef ComponentFactory = Component Function(Map<String, dynamic> json);

/// A type alias for a map of component type names to their factories.
typedef ComponentRegistryMap = Map<String, ComponentFactory>;

/// A registry for mapping component type names to their deserialization factories and their Type.
class ComponentFactoryRegistry {
  final Map<String, ComponentFactory> _factories = {};
  // --- NEW: A map to resolve string names back to Type objects ---
  // --- جدید: یک نقشه برای تبدیل نام‌های رشته‌ای به آبجکت‌های Type ---
  final Map<String, Type> _typeMap = {};

  static final ComponentFactoryRegistry I =
      ComponentFactoryRegistry._internal();

  ComponentFactoryRegistry._internal();

  /// Registers a single component factory and its corresponding Type.
  /// یک فکتوری کامپوننت و Type متناظر آن را ثبت می‌کند.
  void register(String typeName, ComponentFactory factory, Type type) {
    _factories[typeName] = factory;
    _typeMap[typeName] = type;
  }

  /// Registers multiple component factories from a map.
  /// چندین فکتوری کامپوننت را از یک نقشه ثبت می‌کند.
  void registerAll(Map<String, (ComponentFactory, Type)> factories) {
    for (final entry in factories.entries) {
      register(entry.key, entry.value.$1, entry.value.$2);
    }
  }

  /// Creates a component instance from its type name and JSON data.
  /// یک نمونه کامپوننت را از روی نام نوع و داده JSON آن ایجاد می‌کند.
  Component create(String typeName, Map<String, dynamic> json) {
    final factory = _factories[typeName];
    if (factory == null) {
      throw Exception('No factory registered for component type "$typeName". '
          'Ensure you call ComponentFactoryRegistry.I.register() or registerAll() '
          'for all custom serializable components at the start of your application.');
    }
    return factory(json);
  }

  /// --- NEW: Gets the Type object from a string name. ---
  /// --- جدید: آبجکت Type را از روی نام رشته‌ای آن برمی‌گرداند. ---
  Type? getComponentTypeByName(String typeName) {
    return _typeMap[typeName];
  }
}

/// A helper function to register all default serializable components from the core library.
void registerCoreComponents() {
  // Using a record (tuple) to associate factory and Type together.
  final coreComponents = <String, (ComponentFactory, Type)>{
    'PositionComponent': (
      (json) => PositionComponent.fromJson(json),
      PositionComponent
    ),
    'TagsComponent': ((json) => TagsComponent.fromJson(json), TagsComponent),
    'AnimationProgressComponent': (
      (json) => AnimationProgressComponent.fromJson(json),
      AnimationProgressComponent
    ),
    'CounterStateComponent': (
      (json) => CounterStateComponent.fromJson(json),
      CounterStateComponent
    ),
    'MorphingLogicComponent': (
      (json) => MorphingLogicComponent.fromJson(json),
      MorphingLogicComponent
    ),
    'ShapePathComponent': (
      (json) => ShapePathComponent.fromJson(json),
      ShapePathComponent
    ),
    'CustomWidgetComponent': (
      (json) => CustomWidgetComponent.fromJson(json),
      CustomWidgetComponent
    ),
    'ParticleComponent': (
      (json) => ParticleComponent.fromJson(json),
      ParticleComponent
    ),
    'AttractorComponent': (
      (json) => AttractorComponent.fromJson(json),
      AttractorComponent
    ),
    'VelocityComponent': (
      (json) => VelocityComponent.fromJson(json),
      VelocityComponent
    ),
    'ParticleSpawnerComponent': (
      (json) => ParticleSpawnerComponent.fromJson(json),
      ParticleSpawnerComponent
    ),
    'SpawnerLinkComponent': (
      (json) => SpawnerLinkComponent.fromJson(json),
      SpawnerLinkComponent
    ),
    'ChildrenComponent': (
      (json) => ChildrenComponent.fromJson(json),
      ChildrenComponent
    ),
    'HistoryComponent': (
      (json) => HistoryComponent.fromJson(json),
      HistoryComponent
    ),
    'RenderStrategyComponent': (
      (json) => RenderStrategyComponent.fromJson(json),
      RenderStrategyComponent
    ),
    'BlackboardComponent': (
      (json) => BlackboardComponent.fromJson(json),
      BlackboardComponent
    ),
    'PersistenceComponent': (
      (json) => PersistenceComponent.fromJson(json),
      PersistenceComponent
    ),
    'ApiStatusComponent': (
      (json) => ApiStatusComponent.fromJson(json),
      ApiStatusComponent
    ),
    'AppLifecycleComponent': (
      (json) => AppLifecycleComponent.fromJson(json),
      AppLifecycleComponent
    ),
    'WebSocketStateComponent': (
      (json) => WebSocketStateComponent.fromJson(json),
      WebSocketStateComponent
    ),
    'ThemeComponent': ((json) => ThemeComponent.fromJson(json), ThemeComponent),
    'StyleableComponent': (
      (json) => StyleableComponent.fromJson(json),
      StyleableComponent
    ),
    'ScreenInfoComponent': (
      (json) => ScreenInfoComponent.fromJson(json),
      ScreenInfoComponent
    ),
    'CategoryComponent': (
      (json) => CategoryComponent.fromJson(json),
      CategoryComponent
    ),
    'ParentComponent': (
      (json) => ParentComponent.fromJson(json),
      ParentComponent
    ),
    'LinkComponent': ((json) => LinkComponent.fromJson(json), LinkComponent),
    'DecorationComponent': (
      (json) => DecorationComponent.fromJson(json),
      DecorationComponent
    ),
    'DomElementComponent': (
      (json) => DomElementComponent.fromJson(json),
      DomElementComponent
    ),
    'StyleSheetComponent': (
      (json) => StyleSheetComponent.fromJson(json),
      StyleSheetComponent
    ),
    'TargetingComponent': (
      (json) => TargetingComponent.fromJson(json),
      TargetingComponent
    ),
    'CollisionComponent': (
      (json) => CollisionComponent.fromJson(json),
      CollisionComponent
    ),
    'HealthComponent': (
      (json) => HealthComponent.fromJson(json),
      HealthComponent
    ),
    'DamageComponent': (
      (json) => DamageComponent.fromJson(json),
      DamageComponent
    ),
    'InputFocusComponent': (
      (json) => InputFocusComponent.fromJson(json),
      InputFocusComponent
    ),
    'KeyboardInputComponent': (
      (json) => KeyboardInputComponent.fromJson(json),
      KeyboardInputComponent
    ),
    'ListComponent': ((json) => ListComponent.fromJson(json), ListComponent),
    'ListStateComponent': (
      (json) => ListStateComponent.fromJson(json),
      ListStateComponent
    ),
    'AnimateOutComponent': (
      (json) => AnimateOutComponent.fromJson(json),
      AnimateOutComponent
    ),
    'GlobalTransformComponent': (
      (json) => GlobalTransformComponent.fromJson(json),
      GlobalTransformComponent
    ),
    'DrawableComponent': (
      (json) => DrawableComponent.fromJson(json),
      DrawableComponent
    ),
    'LayerComponent': ((json) => LayerComponent.fromJson(json), LayerComponent),
    'ShapeComponent': ((json) => ShapeComponent.fromJson(json), ShapeComponent),
    'StyleComponent': ((json) => StyleComponent.fromJson(json), StyleComponent),
    'SceneRenderPacketComponent': (
      (json) => SceneRenderPacketComponent.fromJson(json),
      SceneRenderPacketComponent
    ),
    'TransformComponent': (
      (json) => TransformComponent.fromJson(json),
      TransformComponent
    ),
    // TimerComponent is not serializable
  };

  ComponentFactoryRegistry.I.registerAll(coreComponents);
}
