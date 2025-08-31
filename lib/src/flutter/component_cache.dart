import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';

/// یک کلاس در ترد UI که وضعیت کامپوننت‌های سریالایز شده را نگهداری (کش) می‌کند
/// و ویجت‌ها را از تغییرات مطلع می‌سازد.
class ComponentCache {
  final NexusManager manager;
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};
  StreamSubscription? _updateSubscription;

  ComponentCache({required this.manager}) {
    _updateSubscription = manager.componentUpdateStream.listen(_onUpdate);
  }

  /// دریافت یک کامپوننت از کش.
  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  /// دریافت ChangeNotifier برای یک موجودیت خاص.
  ChangeNotifier getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void _onUpdate(ComponentUpdate update) {
    final entityCache = _componentCache.putIfAbsent(update.entityId, () => {});
    final notifier = getNotifier(update.entityId);

    final type =
        ComponentFactoryRegistry.I.getComponentType(update.componentTypeName);
    if (type == null) return;

    if (update.isRemoved) {
      entityCache.remove(type);
    } else if (update.componentJson != null) {
      try {
        final component = ComponentFactoryRegistry.I
            .create(update.componentTypeName, update.componentJson!);
        entityCache[type] = component;
      } catch (e) {
        debugPrint(
            '[ComponentCache] Error deserializing ${update.componentTypeName}: $e');
      }
    }
    notifier.notifyListeners();
  }

  void dispose() {
    _updateSubscription?.cancel();
    for (var notifier in _entityNotifiers.values) {
      notifier.dispose();
    }
  }
}

// افزودن یک متد کمکی به رجیستری برای دریافت Type از روی نام
extension ComponentTypeResolver on ComponentFactoryRegistry {
  static final Map<String, Type> _typeMap = {};

  void _cacheType(String name, Type type) {
    _typeMap.putIfAbsent(name, () => type);
  }

  Type? getComponentType(String typeName) {
    return _typeMap[typeName];
  }

  void registerAndCache(String typeName, ComponentFactory factory, Type type) {
    register(typeName, factory);
    _cacheType(typeName, type);
  }
}
