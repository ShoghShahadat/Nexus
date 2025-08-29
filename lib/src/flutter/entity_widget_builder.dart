import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/systems/flutter_rendering_system.dart';

/// A highly performant widget that listens to a single entity using its ID
/// and the rendering system, then rebuilds its child whenever the entity's
/// components change.
///
/// This is the core of the reactive UI layer in Nexus for an isolate-based
/// architecture. It ensures that only the specific parts of the widget tree
/// that depend on an entity are rebuilt, by listening to notifiers provided
/// by the FlutterRenderingSystem.
class EntityWidgetBuilder extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId entityId;
  final Widget Function(BuildContext context) builder;

  const EntityWidgetBuilder({
    super.key,
    required this.renderingSystem,
    required this.entityId,
    required this.builder,
  });

  @override
  State<EntityWidgetBuilder> createState() => _EntityWidgetBuilderState();
}

class _EntityWidgetBuilderState extends State<EntityWidgetBuilder> {
  @override
  void initState() {
    super.initState();
    // Subscribe to the entity's changes via the notifier from the rendering system.
    widget.renderingSystem
        .getNotifier(widget.entityId)
        .addListener(_onEntityChanged);
  }

  @override
  void didUpdateWidget(covariant EntityWidgetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the entity ID or rendering system instance itself changes, update the listener.
    if (widget.entityId != oldWidget.entityId ||
        widget.renderingSystem != oldWidget.renderingSystem) {
      oldWidget.renderingSystem
          .getNotifier(oldWidget.entityId)
          .removeListener(_onEntityChanged);
      widget.renderingSystem
          .getNotifier(widget.entityId)
          .addListener(_onEntityChanged);
    }
  }

  @override
  void dispose() {
    // Unsubscribe to prevent memory leaks.
    widget.renderingSystem
        .getNotifier(widget.entityId)
        .removeListener(_onEntityChanged);
    super.dispose();
  }

  void _onEntityChanged() {
    // When the entity notifies of a change, call setState on this widget
    // to trigger a rebuild of its subtree only.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // The builder function doesn't need any parameters, as it can get all
    // necessary data from the renderingSystem available in its parent scope.
    return widget.builder(context);
  }
}
