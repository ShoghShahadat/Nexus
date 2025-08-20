import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

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

  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};
  final Map<EntityId, Widget> _selfWidgetCache = {};

  FlutterRenderingSystem({required this.builders});

  void setManager(NexusManager manager) {
    _manager = manager;
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  // --- NEW: Restored this useful helper method ---
  /// Finds all entity IDs that have a specific tag.
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
  // --- END NEW ---

  ChangeNotifier _getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void updateFromPackets(List<RenderPacket> packets) {
    if (packets.isEmpty) return;

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
          if (kDebugMode) {
            print(
                '[RenderingSystem] ERROR deserializing $typeName for ID ${packet.id}: $e');
          }
        }
      }
    }

    for (final id in updatedEntities) {
      _selfWidgetCache.remove(id);
      (_getNotifier(id) as ChangeNotifier).notifyListeners();
    }

    if (needsGlobalNotify) {
      notifyListeners();
    }
  }

  Widget build(BuildContext context) {
    if (_manager == null || _componentCache.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    EntityId? rootId;
    try {
      rootId = _componentCache.entries.firstWhere((entry) {
        final component = entry.value[TagsComponent];
        if (component is TagsComponent) {
          return component.hasTag('root');
        }
        return false;
      }).key;
    } catch (e) {
      return const Center(child: Text("Error: 'root' entity not found."));
    }

    return _buildEntityWidget(context, rootId);
  }

  Widget _buildEntityWidget(BuildContext context, EntityId id) {
    return AnimatedBuilder(
      animation: _getNotifier(id),
      builder: (context, _) {
        final strategy = get<RenderStrategyComponent>(id)?.behavior ??
            RenderBehavior.dynamicView;

        if (strategy == RenderBehavior.staticScope &&
            _selfWidgetCache.containsKey(id)) {
          return _selfWidgetCache[id]!;
        }

        final customWidgetComp = get<CustomWidgetComponent>(id);
        if (customWidgetComp == null) {
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
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children);
        } else if (customWidgetComp.widgetType == 'row') {
          childrenWidget = Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: children);
        } else if (children.isNotEmpty) {
          childrenWidget = children.first;
        } else {
          childrenWidget = const SizedBox.shrink();
        }

        final builder = builders[customWidgetComp.widgetType];
        Widget finalWidget;

        if (builder != null) {
          final parentShell =
              builder(context, id, this, _manager!, childrenWidget);
          finalWidget = parentShell;
        } else {
          finalWidget = childrenWidget;
        }

        if (strategy == RenderBehavior.staticScope) {
          _selfWidgetCache[id] = finalWidget;
        }

        return finalWidget;
      },
    );
  }
}
