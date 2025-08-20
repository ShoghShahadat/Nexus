import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/render_packet.dart';

/// A function signature for building a widget based on an entity's ID and
/// the current rendering controller.
typedef TaggedWidgetBuilder = Widget Function(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager);

/// A UI-side controller that extends ChangeNotifier. It receives RenderPackets
/// from the background isolate, caches the component data, and notifies its
/// listeners to rebuild the UI.
class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<String, TaggedWidgetBuilder> builders;
  NexusIsolateManager? _isolateManager;

  FlutterRenderingSystem({required this.builders});

  void setManager(NexusIsolateManager manager) {
    _isolateManager = manager;
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  List<EntityId> getAllIdsWithTag(String tag) {
    final List<EntityId> ids = [];
    for (final entry in _componentCache.entries) {
      final tagsComp = entry.value[TagsComponent] as TagsComponent?;
      if (tagsComp != null && tagsComp.hasTag(tag)) {
        ids.add(entry.key);
      }
    }
    return ids;
  }

  void addUiEntity(EntityId id, Set<String> tags) {
    if (!_componentCache.containsKey(id)) {
      _componentCache[id] = {};
    }
    _componentCache[id]![PositionComponent] =
        PositionComponent(x: 0, y: 0, width: 0, height: 0);
    _componentCache[id]![TagsComponent] = TagsComponent(tags);
    notifyListeners();
  }

  void updateFromPackets(List<RenderPacket> packets) {
    if (packets.isEmpty) return;
    bool needsNotify = false;
    for (final packet in packets) {
      needsNotify = true;
      if (packet.isRemoved) {
        _componentCache.remove(packet.id);
        continue;
      }
      if (!_componentCache.containsKey(packet.id)) {
        _componentCache[packet.id] = {};
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
                '[RenderingSystem] ERROR deserializing component $typeName for ID ${packet.id}: $e');
          }
        }
      }
    }
    if (needsNotify) {
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isolateManager == null) {
      return const Center(
          child: Text("Nexus Isolate Manager not initialized."));
    }
    if (_componentCache.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Widget> children = [];
    for (final entityId in _componentCache.keys) {
      final pos = get<PositionComponent>(entityId);
      final tags = get<TagsComponent>(entityId);
      if (pos == null || tags == null) continue;

      TaggedWidgetBuilder? builder;
      for (final tag in tags.tags) {
        if (builders.containsKey(tag)) {
          builder = builders[tag];
          break;
        }
      }
      if (builder == null) continue;

      children.add(
        Positioned(
          key: ValueKey(entityId),
          left: pos.x,
          top: pos.y,
          width: pos.width,
          height: pos.height,
          child: Transform.scale(
            scale: pos.scale,
            child: builder(context, entityId, this, _isolateManager!),
          ),
        ),
      );
    }

    // *** FIX: Use a SizedBox with a fixed height to define the scrollable area. ***
    // This allows the parent SingleChildScrollView to work correctly with the Stack.
    return SizedBox(
      height: 1200, // A height large enough to contain all elements
      child: Stack(children: children),
    );
  }
}
