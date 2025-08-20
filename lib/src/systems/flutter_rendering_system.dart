import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/render_packet.dart';

/// A function signature for building a widget based on an entity's ID and
/// the current rendering controller.
typedef TaggedWidgetBuilder = Widget Function(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager);

/// The FlutterRenderingSystem is no longer a traditional System that runs in
/// the world's update loop. Instead, it's a UI-side controller that extends
/// ChangeNotifier. It receives RenderPackets from the background isolate,
/// caches the component data, and notifies its listeners (like NexusWidget)
/// to rebuild the UI.
class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<String, TaggedWidgetBuilder> builders;
  NexusIsolateManager? _isolateManager;

  FlutterRenderingSystem({required this.builders});

  /// Sets the isolate manager for this rendering system. This is called by
  /// the NexusWidget once the manager is created.
  void setManager(NexusIsolateManager manager) {
    _isolateManager = manager;
  }

  /// Retrieves a component of a specific type for a given entity ID from the cache.
  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  /// Retrieves a list of entity IDs that have a specific tag from the cache.
  /// This is useful for builders that need to render a collection of entities
  /// based on their tags (e.g., all particles).
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

  /// Adds a UI-only entity directly to the rendering system's cache.
  void addUiEntity(EntityId id, Set<String> tags) {
    if (!_componentCache.containsKey(id)) {
      _componentCache[id] = {};
    }
    _componentCache[id]![PositionComponent] =
        PositionComponent(x: 0, y: 0, width: 0, height: 0);
    _componentCache[id]![TagsComponent] = TagsComponent(tags);
    notifyListeners();
  }

  /// Updates the internal cache with data from RenderPackets and notifies the UI.
  void updateFromPackets(List<RenderPacket> packets) {
    if (packets.isEmpty) {
      return;
    }
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
          // Error handling for deserialization can be added here.
        }
      }
    }
    if (needsNotify) {
      notifyListeners();
    }
  }

  /// Builds the widget representation of the current state of the world.
  @override
  Widget build(BuildContext context) {
    if (_isolateManager == null) {
      return const Center(
          child: Text("Nexus Isolate Manager not initialized."));
    }
    if (_componentCache.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final renderableEntities = _componentCache.keys.toList();
    final List<Widget> children = [];
    for (final entityId in renderableEntities) {
      final pos = get<PositionComponent>(entityId);
      final tags = get<TagsComponent>(entityId);

      if (pos == null || tags == null) {
        continue;
      }

      TaggedWidgetBuilder? builder;
      for (final tag in tags.tags) {
        if (builders.containsKey(tag)) {
          builder = builders[tag];
          break;
        }
      }

      if (builder == null) {
        continue;
      }

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

    // *** FIX: Wrap the Stack in a SizedBox.expand() ***
    // This ensures the Stack fills the available space, preventing it from
    // collapsing to 0x0 size when it only contains Positioned children.
    return SizedBox.expand(
      child: Stack(children: children),
    );
  }
}
