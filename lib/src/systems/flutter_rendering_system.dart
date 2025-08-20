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

  /// Updates the internal cache with data from RenderPackets and notifies the UI.
  void updateFromPackets(List<RenderPacket> packets) {
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
        final component =
            ComponentFactoryRegistry.I.create(typeName, componentJson);
        _componentCache[packet.id]![component.runtimeType] = component;
      }
    }
    if (needsNotify) {
      notifyListeners();
    }
  }

  /// Builds the widget representation of the current state of the world.
  Widget build(BuildContext context) {
    if (_isolateManager == null) {
      return const Center(
          child: Text("Nexus Isolate Manager not initialized."));
    }
    if (_componentCache.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final renderableEntities = _componentCache.keys.toList();

    return Stack(
      children: renderableEntities.map((entityId) {
        final pos = get<PositionComponent>(entityId);
        final tags = get<TagsComponent>(entityId);

        if (pos == null || tags == null) return const SizedBox.shrink();

        // Find the first tag that has a registered builder.
        TaggedWidgetBuilder? builder;
        for (final tag in tags.tags) {
          if (builders.containsKey(tag)) {
            builder = builders[tag];
            break;
          }
        }

        if (builder == null) return const SizedBox.shrink();

        return Positioned(
          key: ValueKey(entityId),
          left: pos.x,
          top: pos.y,
          width: pos.width,
          height: pos.height,
          child: Transform.scale(
            scale: pos.scale,
            child: builder(context, entityId, this, _isolateManager!),
          ),
        );
      }).toList(),
    );
  }
}
