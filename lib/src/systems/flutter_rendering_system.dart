import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

// --- MODIFIED: Added a 'child' parameter for proper widget composition ---
typedef EntityWidgetBuilderFunc = Widget Function(
    BuildContext context,
    EntityId id,
    FlutterRenderingSystem controller,
    NexusManager manager,
    Widget child);

/// A UI-side controller that recursively builds a Flutter widget tree from a
/// hierarchical entity structure with granular, entity-level state management.
class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<String, EntityWidgetBuilderFunc> builders;
  NexusManager? _manager;

  // Granular State Management
  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};
  final Map<EntityId, Widget> _selfWidgetCache = {};

  FlutterRenderingSystem({required this.builders});

  void setManager(NexusManager manager) {
    _manager = manager;
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  ChangeNotifier _getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void updateFromPackets(List<RenderPacket> packets) {
    if (packets.isEmpty) return;

    // --- LOGGING ---
    debugPrint(
        '[RenderingSystem] Received ${packets.length} packets. IDs: ${packets.map((p) => p.id).toList()}');
    // --- END LOGGING ---

    final Set<EntityId> updatedEntities = {};
    bool needsGlobalNotify = false;

    for (final packet in packets) {
      final isNewEntity = !_componentCache.containsKey(packet.id);
      updatedEntities.add(packet.id);

      if (packet.isRemoved) {
        _componentCache.remove(packet.id);
        _entityNotifiers.remove(packet.id)?.dispose();
        _selfWidgetCache.remove(packet.id);
        needsGlobalNotify = true;
        continue;
      }

      if (isNewEntity) {
        _componentCache[packet.id] = {};
        needsGlobalNotify = true;
      }

      for (final typeName in packet.components.keys) {
        final componentJson = packet.components[typeName]!;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          _componentCache[packet.id]![component.runtimeType] = component;
        } catch (e) {
          debugPrint(
              '[RenderingSystem] ERROR deserializing $typeName for ID ${packet.id}: $e');
        }
      }
    }

    for (final id in updatedEntities) {
      _selfWidgetCache.remove(id);
      // --- LOGGING ---
      debugPrint(
          '[RenderingSystem] Notifying granular listener for Entity ID: $id');
      // --- END LOGGING ---
      (_getNotifier(id) as ChangeNotifier).notifyListeners();
    }

    if (needsGlobalNotify) {
      // --- LOGGING ---
      debugPrint(
          '[RenderingSystem] Notifying GLOBAL listener for structural change.');
      // --- END LOGGING ---
      notifyListeners();
    }
  }

  Widget build(BuildContext context) {
    // --- LOGGING ---
    debugPrint('[RenderingSystem] Main build method called.');
    // --- END LOGGING ---

    if (_manager == null || _componentCache.isEmpty) {
      debugPrint(
          '[RenderingSystem] Build failed: Manager is null or component cache is empty.');
      return const Center(child: CircularProgressIndicator());
    }

    EntityId? rootId;
    try {
      rootId = _componentCache.entries.firstWhere((entry) {
        final tags = entry.value[TagsComponent] as TagsComponent?;
        return tags?.hasTag('root') ?? false;
      }).key;
      debugPrint('[RenderingSystem] Found root entity with ID: $rootId');
    } catch (e) {
      debugPrint(
          '[RenderingSystem] FATAL: Could not find any entity with "root" tag. Building aborted.');
      return const Center(child: Text("Error: 'root' entity not found."));
    }

    return _buildEntityWidget(context, rootId);
  }

  Widget _buildEntityWidget(BuildContext context, EntityId id) {
    return AnimatedBuilder(
      animation: _getNotifier(id),
      builder: (context, _) {
        // --- LOGGING ---
        final customWidgetComp = get<CustomWidgetComponent>(id);
        debugPrint(
            '[RenderingSystem] Rebuilding widget for Entity ID: $id (Type: ${customWidgetComp?.widgetType ?? "N/A"})');
        // --- END LOGGING ---

        final strategy = get<RenderStrategyComponent>(id)?.behavior ??
            RenderBehavior.dynamicView;

        if (strategy == RenderBehavior.staticScope &&
            _selfWidgetCache.containsKey(id)) {
          debugPrint(
              '[RenderingSystem]   -> Returning STATIC SCOPE cached widget for ID: $id');
          return _selfWidgetCache[id]!;
        }

        if (customWidgetComp == null) {
          debugPrint(
              '[RenderingSystem]   -> ABORT: No CustomWidgetComponent found for ID: $id');
          return const SizedBox.shrink();
        }

        final childrenComp = get<ChildrenComponent>(id);
        final children = childrenComp?.children
                .map((childId) => _buildEntityWidget(context, childId))
                .toList() ??
            [];

        final Widget childrenWidget;
        if (customWidgetComp.widgetType == 'wrap') {
          childrenWidget = Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.center,
              children: children);
        } else if (customWidgetComp.widgetType == 'column') {
          childrenWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children);
        } else if (children.isNotEmpty) {
          childrenWidget = children.first;
        } else {
          childrenWidget = const SizedBox.shrink();
        }

        final builder = builders[customWidgetComp.widgetType];
        Widget finalWidget;

        if (builder != null) {
          debugPrint(
              '[RenderingSystem]   -> Calling custom builder for type: "${customWidgetComp.widgetType}"');
          final parentShell =
              builder(context, id, this, _manager!, childrenWidget);
          finalWidget = parentShell;
        } else {
          debugPrint(
              '[RenderingSystem]   -> No custom builder found. Returning layout widget directly.');
          finalWidget = childrenWidget;
        }

        if (strategy == RenderBehavior.staticScope) {
          debugPrint(
              '[RenderingSystem]   -> Caching widget for STATIC SCOPE ID: $id');
          _selfWidgetCache[id] = finalWidget;
        }

        return finalWidget;
      },
    );
  }
}
