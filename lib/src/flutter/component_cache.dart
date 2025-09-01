import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';

/// یک کلاس در ترد UI که وضعیت کامپوننت‌های سریالایز شده را نگهداری (کش) می‌کند
/// و ویجت‌ها را از تغییرات مطلع می‌سازد.
class ComponentCache {
  final NexusManager manager;
  final Map<EntityId, Map<String, Component>> _componentCache = {};
  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};
  StreamSubscription? _updateSubscription;

  // --- NEW: A stream to signal when the cache is ready (has received first data) ---
  final _readyController = StreamController<void>.broadcast();
  Stream<void> get onReady => _readyController.stream;
  bool _isReady = false;

  ComponentCache({required this.manager}) {
    _updateSubscription = manager.componentUpdateStream.listen(_onUpdate);
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T.toString()] as T?;
  }

  ChangeNotifier getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void _onUpdate(ComponentUpdate update) {
    // --- PRO LOGGING ---
    debugPrint(
        "📬 [ComponentCache] Received update for Entity ${update.entityId}: Component '${update.componentTypeName}', isRemoved: ${update.isRemoved}");

    final entityCache = _componentCache.putIfAbsent(update.entityId, () => {});
    final notifier = getNotifier(update.entityId);

    if (update.isRemoved) {
      entityCache.remove(update.componentTypeName);
    } else if (update.componentJson != null) {
      try {
        final component = ComponentFactoryRegistry.I
            .create(update.componentTypeName, update.componentJson!);
        entityCache[update.componentTypeName] = component;
      } catch (e) {
        debugPrint(
            "❌ [ComponentCache] ERROR deserializing '${update.componentTypeName}': $e");
      }
    }

    // --- PRO LOGGING ---
    debugPrint(
        "🔔 [ComponentCache] Notifying listeners for Entity ${update.entityId}.");
    notifier.notifyListeners();

    // --- NEW: Signal readiness on first data received ---
    if (!_isReady) {
      _isReady = true;
      debugPrint(
          "✅ [ComponentCache] Cache is now ready. Firing onReady event.");
      _readyController.add(null);
    }
  }

  void dispose() {
    _updateSubscription?.cancel();
    _readyController.close();
    for (var notifier in _entityNotifiers.values) {
      notifier.dispose();
    }
    debugPrint("🗑️ [ComponentCache] Disposed.");
  }
}
