import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/render_packet.dart';
import 'package:flutter/foundation.dart'; // برای استفاده از debugPrint

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
    debugPrint('[RenderingSystem] IsolateManager set.');
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
    // این لاگ می‌تواند خروجی بسیار زیادی تولید کند، تنها در صورت نیاز فعال شود.
    // debugPrint('[RenderingSystem] Found ${ids.length} entities with tag "$tag".');
    return ids;
  }

  /// Adds a UI-only entity directly to the rendering system's cache.
  ///
  /// This is used for entities that exist purely on the UI thread and are
  /// not managed by the background NexusWorld logic. It also adds a dummy
  /// `PositionComponent` to ensure compatibility with the `build` method's
  /// expectation for positioning, even if the widget itself handles its size/position.
  void addUiEntity(EntityId id, Set<String> tags) {
    debugPrint(
        '[RenderingSystem] Adding UI-only entity ID: $id with tags: $tags');
    if (!_componentCache.containsKey(id)) {
      _componentCache[id] = {};
    }
    _componentCache[id]![PositionComponent] =
        PositionComponent(x: 0, y: 0, width: 0, height: 0);
    _componentCache[id]![TagsComponent] = TagsComponent(tags);
    notifyListeners();
    debugPrint(
        '[RenderingSystem] UI-only entity ID: $id added to cache. Cache size: ${_componentCache.length}');
  }

  /// Updates the internal cache with data from RenderPackets and notifies the UI.
  void updateFromPackets(List<RenderPacket> packets) {
    debugPrint(
        '[RenderingSystem] <<< Received ${packets.length} render packets. >>>'); // لاگ جدید
    if (packets.isEmpty) {
      debugPrint(
          '[RenderingSystem] Received empty packet list. Skipping update.');
      return;
    }
    bool needsNotify = false;
    for (final packet in packets) {
      needsNotify = true;
      debugPrint(
          '[RenderingSystem] Processing packet for Entity ID: ${packet.id}');
      if (packet.isRemoved) {
        _componentCache.remove(packet.id);
        debugPrint(
            '[RenderingSystem] Removed entity ID: ${packet.id}. Cache size: ${_componentCache.length}');
        continue;
      }

      if (!_componentCache.containsKey(packet.id)) {
        _componentCache[packet.id] = {};
        debugPrint(
            '[RenderingSystem] Initializing cache for entity ID: ${packet.id}.');
      }

      for (final typeName in packet.components.keys) {
        final componentJson = packet.components[typeName]!;
        // debugPrint('[RenderingSystem] Deserializing component type: $typeName for ID: ${packet.id}');
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          _componentCache[packet.id]![component.runtimeType] = component;

          // لاگ‌های دقیق‌تر برای کامپوننت‌های ذرات و جاذب
          if (component is PositionComponent) {
            debugPrint(
                '  [RenderingSystem] PositionComponent for ${packet.id}: x=${component.x.toInt()}, y=${component.y.toInt()}, w=${component.width.toInt()}, h=${component.height.toInt()}, scale=${component.scale}');
          }
          if (component is ParticleComponent) {
            debugPrint(
                '  [RenderingSystem] ParticleComponent for ${packet.id}: age=${component.age.toInt()}/${component.maxAge.toInt()}, initialColor=${component.initialColorValue.toRadixString(16)}, finalColor=${component.finalColorValue.toRadixString(16)}');
          }
          if (component is AttractorComponent) {
            debugPrint(
                '  [RenderingSystem] AttractorComponent for ${packet.id}: strength=${component.strength}');
          }
          if (component is SpawnerComponent) {
            debugPrint(
                '  [RenderingSystem] SpawnerComponent for ${packet.id}: spawnRate=${component.spawnRate}');
          }
          if (component is TagsComponent) {
            debugPrint(
                '  [RenderingSystem] TagsComponent for ${packet.id}: tags=${component.tags}');
          }
        } catch (e) {
          debugPrint(
              '[RenderingSystem] ERROR deserializing component $typeName for ID ${packet.id}: $e');
        }
      }
    }
    if (needsNotify) {
      notifyListeners();
      debugPrint(
          '[RenderingSystem] Notified listeners. Final cache size: ${_componentCache.length}');
    }
  }

  /// Builds the widget representation of the current state of the world.
  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[RenderingSystem] Building UI. Current cache size: ${_componentCache.length}');
    if (_isolateManager == null) {
      debugPrint(
          '[RenderingSystem] Isolate Manager is null. Returning error text.');
      return const Center(
          child: Text("Nexus Isolate Manager not initialized."));
    }
    if (_componentCache.isEmpty) {
      debugPrint(
          '[RenderingSystem] Component cache is empty. Showing CircularProgressIndicator.');
      return const Center(child: CircularProgressIndicator());
    }

    final renderableEntities = _componentCache.keys.toList();
    debugPrint(
        '[RenderingSystem] Number of renderable entities: ${renderableEntities.length}');

    final List<Widget> children = [];
    for (final entityId in renderableEntities) {
      final pos = get<PositionComponent>(entityId);
      final tags = get<TagsComponent>(entityId);

      if (pos == null || tags == null) {
        debugPrint(
            '[RenderingSystem] Entity ID: $entityId is missing PositionComponent or TagsComponent. Skipping rendering for this entity.');
        continue; // از رندر این Entity صرفنظر کنید.
      }

      TaggedWidgetBuilder? builder;
      for (final tag in tags.tags) {
        if (builders.containsKey(tag)) {
          builder = builders[tag];
          debugPrint(
              '[RenderingSystem] Found builder for tag: "$tag" for Entity ID: $entityId');
          break;
        }
      }

      if (builder == null) {
        debugPrint(
            '[RenderingSystem] No suitable builder found for Entity ID: $entityId with tags: ${tags.tags}. Skipping rendering for this entity.');
        continue; // از رندر این Entity صرفنظر کنید.
      }

      debugPrint(
          '[RenderingSystem] Rendering Entity ID: $entityId at x:${pos.x.toInt()}, y:${pos.y.toInt()}, w:${pos.width.toInt()}, h:${pos.height.toInt()}, scale:${pos.scale}');
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
    debugPrint(
        '[RenderingSystem] Total widgets added to Stack: ${children.length}');
    return Stack(children: children);
  }
}
