import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

// *** FIX: Removed all dependencies on the example project. ***

/// A function signature for building a widget based on an entity's ID and data.
typedef EntityWidgetBuilderFunc = Widget Function(
    BuildContext context,
    EntityId id,
    FlutterRenderingSystem controller,
    NexusIsolateManager manager);

/// A UI-side controller that recursively builds a Flutter widget tree from a
/// hierarchical entity structure.
class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<String, EntityWidgetBuilderFunc> builders;
  NexusIsolateManager? _isolateManager;

  FlutterRenderingSystem({required this.builders});

  void setManager(NexusIsolateManager manager) {
    _isolateManager = manager;
  }

  T? get<T extends Component>(EntityId id) {
    return _componentCache[id]?[T] as T?;
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

  // *** FIX: Removed @override annotation as this method does not override anything. ***
  Widget build(BuildContext context) {
    if (_isolateManager == null || _componentCache.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    EntityId? rootId;
    for (final entry in _componentCache.entries) {
      final tags = entry.value[TagsComponent] as TagsComponent?;
      if (tags != null && tags.hasTag('root')) {
        rootId = entry.key;
        break;
      }
    }

    if (rootId == null) {
      return const Center(
          child: Text("Error: 'root' entity not found in the world."));
    }

    return _buildEntityWidget(context, rootId);
  }

  Widget _buildEntityWidget(BuildContext context, EntityId id) {
    final customWidgetComp = get<CustomWidgetComponent>(id);
    if (customWidgetComp == null) {
      return const SizedBox.shrink();
    }

    final widgetType = customWidgetComp.widgetType;
    final childrenComp = get<ChildrenComponent>(id);
    final children = childrenComp?.children
            .map((childId) => _buildEntityWidget(context, childId))
            .toList() ??
        [];

    switch (widgetType) {
      case 'column':
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch to fill width
          children: children,
        );
      case 'wrap':
        return Padding(
          padding: const EdgeInsets.all(16.0), // Add padding around the wrap
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center, // Center the cards
            children: children,
          ),
        );
      case 'padding':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
        );
      default:
        final builder = builders[widgetType];
        if (builder != null) {
          return builder(context, id, this, _isolateManager!);
        }
    }

    return Text('Unknown widget type: $widgetType');
  }
}
