import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

// *** FIX: Changed parameter type from concrete implementation to the abstract interface. ***
/// A function signature for building a widget based on an entity's ID and data.
typedef EntityWidgetBuilderFunc = Widget Function(BuildContext context,
    EntityId id, FlutterRenderingSystem controller, NexusManager manager);

/// A UI-side controller that recursively builds a Flutter widget tree from a
/// hierarchical entity structure.
class FlutterRenderingSystem extends ChangeNotifier {
  final Map<EntityId, Map<Type, Component>> _componentCache = {};
  final Map<String, EntityWidgetBuilderFunc> builders;
  // *** FIX: Changed the manager type to the abstract NexusManager. ***
  NexusManager? _manager;

  FlutterRenderingSystem({required this.builders});

  // *** FIX: Changed the parameter type to the abstract NexusManager. ***
  void setManager(NexusManager manager) {
    _manager = manager;
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

  Widget build(BuildContext context) {
    if (_manager == null || _componentCache.isEmpty) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      case 'wrap':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
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
          // The manager passed to the builder is now correctly typed.
          return builder(context, id, this, _manager!);
        }
    }

    return Text('Unknown widget type: $widgetType');
  }
}
