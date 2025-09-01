import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';

/// A class on the UI thread that caches the state of serialized components
/// and notifies widgets of changes.
class ComponentCache {
  final NexusManager manager;
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};
  StreamSubscription? _updateSubscription;
  bool _isReady = false;

  final Completer<void> _readyCompleter = Completer<void>();

  /// A Future that completes when the first batch of component updates
  /// has been received from the logic isolate.
  Future<void> get onReady => _readyCompleter.future;

  ComponentCache({required this.manager}) {
    debugPrint('📬 [ComponentCache] Created and listening for updates.');
    _updateSubscription = manager.componentUpdateStream.listen(_onUpdate);
  }

  /// Gets a component from the cache.
  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  /// Gets the ChangeNotifier for a specific entity.
  ChangeNotifier getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void _onUpdate(ComponentUpdate update) {
    debugPrint(
        '📬 [ComponentCache] Received update for Entity ${update.entityId}: Component \'${update.componentTypeName}\', isRemoved: ${update.isRemoved}');

    final entityCache = _componentCache.putIfAbsent(update.entityId, () => {});
    final notifier = getNotifier(update.entityId);

    // --- CRITICAL FIX: Use the central registry to resolve the Type ---
    // --- اصلاح حیاتی: از رجیستری مرکزی برای پیدا کردن Type استفاده می‌کند ---
    final componentType = ComponentFactoryRegistry.I
        .getComponentTypeByName(update.componentTypeName);

    if (componentType == null) {
      debugPrint(
          '❓ [ComponentCache] Could not resolve component type for name: "${update.componentTypeName}"');
      return;
    }

    if (update.isRemoved) {
      entityCache.remove(componentType);
    } else if (update.componentJson != null) {
      try {
        final component = ComponentFactoryRegistry.I
            .create(update.componentTypeName, update.componentJson!);
        entityCache[componentType] = component;
      } catch (e) {
        debugPrint(
            '❌ [ComponentCache] ERROR deserializing \'${update.componentTypeName}\': $e');
      }
    }

    debugPrint(
        '🔔 [ComponentCache] Notifying listeners for Entity ${update.entityId}.');
    notifier.notifyListeners();

    if (!_isReady && !_readyCompleter.isCompleted) {
      _isReady = true;
      debugPrint(
          '✅ [ComponentCache] Cache is now ready. Firing onReady event.');
      _readyCompleter.complete();
    }
  }

  void dispose() {
    _updateSubscription?.cancel();
    for (var notifier in _entityNotifiers.values) {
      notifier.dispose();
    }
  }
}
