import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/render_strategy_component.dart';

/// A function signature for building a widget based on an entity's ID and data.
typedef EntityWidgetBuilderFunc = Widget Function(BuildContext context,
    EntityId id, FlutterRenderingSystem controller, NexusManager manager);

/// A UI-side controller that recursively builds a Flutter widget tree from a
/// hierarchical entity structure with granular, entity-level state management.
class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<String, EntityWidgetBuilderFunc> builders;
  NexusManager? _manager;

  // --- NEW: Granular State Management ---
  /// A map of individual notifiers for each entity.
  final Map<EntityId, ChangeNotifier> _entityNotifiers = {};

  /// A cache for the widget subtree of children, used by the `staticShell` behavior.
  final Map<EntityId, Widget> _childrenWidgetCache = {};

  /// A cache for the entire widget, used by the `staticScope` behavior.
  final Map<EntityId, Widget> _selfWidgetCache = {};
  // --- END NEW ---

  FlutterRenderingSystem({required this.builders});

  void setManager(NexusManager manager) {
    _manager = manager;
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
  }

  /// Gets or creates a notifier for a specific entity ID.
  ChangeNotifier _getNotifier(EntityId id) {
    return _entityNotifiers.putIfAbsent(id, () => ChangeNotifier());
  }

  void updateFromPackets(List<RenderPacket> packets) {
    if (packets.isEmpty) return;

    final Set<EntityId> updatedEntities = {};

    for (final packet in packets) {
      updatedEntities.add(packet.id);
      if (packet.isRemoved) {
        _componentCache.remove(packet.id);
        _entityNotifiers.remove(packet.id)?.dispose();
        _childrenWidgetCache.remove(packet.id);
        _selfWidgetCache.remove(packet.id);
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
                '[RenderingSystem] ERROR deserializing $typeName for ID ${packet.id}: $e');
          }
        }
      }
    }

    // Notify only the listeners for the updated entities.
    for (final id in updatedEntities) {
      _getNotifier(id).notifyListeners();
    }
  }

  Widget build(BuildContext context) {
    if (_manager == null || _componentCache.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final rootId = _componentCache.entries.firstWhere((entry) {
      final tags = entry.value[TagsComponent] as TagsComponent?;
      return tags?.hasTag('root') ?? false;
    }, orElse: () => _componentCache.entries.first).key;

    return _buildEntityWidget(context, rootId);
  }

  Widget _buildEntityWidget(BuildContext context, EntityId id) {
    // Each entity's widget is wrapped in an AnimatedBuilder listening
    // to its own specific notifier.
    return AnimatedBuilder(
      animation: _getNotifier(id),
      builder: (context, child) {
        final strategy = get<RenderStrategyComponent>(id)?.behavior ??
            RenderBehavior.dynamicView;

        // Handle static scope: if widget is cached, return it immediately.
        if (strategy == RenderBehavior.staticScope &&
            _selfWidgetCache.containsKey(id)) {
          return _selfWidgetCache[id]!;
        }

        final customWidgetComp = get<CustomWidgetComponent>(id);
        if (customWidgetComp == null) {
          return const SizedBox.shrink();
        }

        final widgetType = customWidgetComp.widgetType;
        Widget builtChildren;

        // Handle shell vs. dynamic children rendering
        if (strategy == RenderBehavior.staticShell &&
            _childrenWidgetCache.containsKey(id)) {
          builtChildren = _childrenWidgetCache[id]!;
        } else {
          final childrenComp = get<ChildrenComponent>(id);
          final children = childrenComp?.children
                  .map((childId) => _buildEntityWidget(context, childId))
                  .toList() ??
              [];

          // This is a simple way to represent the children tree.
          // In a real app, how you structure this depends on the parent widget.
          // For this example, we'll assume a Column for multiple children.
          if (children.length > 1) {
            builtChildren = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
          } else if (children.length == 1) {
            builtChildren = children.first;
          } else {
            builtChildren = const SizedBox.shrink();
          }
          _childrenWidgetCache[id] = builtChildren;
        }

        // Build the actual widget using the builder
        final builder = builders[widgetType];
        Widget finalWidget;
        if (builder != null) {
          finalWidget = builder(context, id, this, _manager!);
        } else {
          finalWidget = Text('Unknown widget type: $widgetType');
        }

        // This is a conceptual implementation. A real implementation would
        // need the builder to accept a `child` parameter. For now, we assume
        // the builder knows how to handle its children via the controller.
        // For simplicity, we'll just return the parent widget.
        // A more robust solution uses a builder pattern like:
        // finalWidget = builder(context, id, this, _manager!, child: builtChildren);

        if (strategy == RenderBehavior.staticScope) {
          _selfWidgetCache[id] = finalWidget;
        }

        return finalWidget;
      },
    );
  }
}
