import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

abstract class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};

  NexusManager? _manager;
  NexusManager? get manager => _manager;

  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};

  FlutterRenderingSystem();

  void setManager(NexusManager manager) {
    _manager = manager;
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  List<EntityId> getAllIdsWithTag(String tag) {
    final ids = <EntityId>[];
    for (final entry in _componentCache.entries) {
      final tagsComponent = entry.value[TagsComponent];
      if (tagsComponent is TagsComponent && tagsComponent.hasTag(tag)) {
        ids.add(entry.key);
      }
    }
    return ids;
  }

  ChangeNotifier getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void updateFromPackets(List<RenderPacket> packets) {
    if (packets.isEmpty) return;

    // *** PRO LOGGING: Log incoming data ***
    // debugPrint(
    // "📦 [RenderingSystem] Received ${packets.length} packet(s) from logic world.");

    final Set<EntityId> updatedEntities = {};
    bool needsGlobalNotify = false;

    for (final packet in packets) {
      final isNewEntity = !_componentCache.containsKey(packet.id);
      updatedEntities.add(packet.id);

      if (packet.isRemoved) {
        _componentCache.remove(packet.id);
        _entityNotifiers.remove(packet.id)?.dispose();
        needsGlobalNotify = true;
        // debugPrint("  - 🗑️ Processed removal for Entity ${packet.id}.");
        continue;
      }

      if (isNewEntity) {
        _componentCache[packet.id] = {};
        needsGlobalNotify = true;
        // debugPrint("  - ✨ Processed new Entity ${packet.id}.");
      } else {
        // debugPrint("  - 🔄 Processing update for Entity ${packet.id}.");
      }

      for (final typeName in packet.components.keys) {
        final componentJson = packet.components[typeName]!;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          _componentCache[packet.id]![component.runtimeType] = component;
        } catch (e) {
          if (kDebugMode) {
            print(
                '[RenderingSystem] ERROR deserializing $typeName for ID ${packet.id}: $e');
          }
        }
      }
    }

    for (final id in updatedEntities) {
      getNotifier(id).notifyListeners();
    }

    if (needsGlobalNotify) {
      // *** PRO LOGGING: Log notification event ***
      // debugPrint(
      // "📢 [RenderingSystem] Cache updated. Notifying global listeners (e.g., for new/removed entities).");
      notifyListeners();
    }
  }

  Widget build(BuildContext context);
}
