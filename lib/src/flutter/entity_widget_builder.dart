import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/entity.dart';

/// A highly performant widget that listens to a single [Entity] and rebuilds
/// its child whenever the entity's components change.
///
/// This is the core of the reactive UI layer in Nexus. It ensures that only
/// the specific parts of the widget tree that depend on an entity are rebuilt,
/// preventing unnecessary builds of the entire screen.
class EntityWidgetBuilder extends StatefulWidget {
  final Entity entity;
  final Widget Function(BuildContext context, Entity entity) builder;

  const EntityWidgetBuilder({
    super.key,
    required this.entity,
    required this.builder,
  });

  @override
  State<EntityWidgetBuilder> createState() => _EntityWidgetBuilderState();
}

class _EntityWidgetBuilderState extends State<EntityWidgetBuilder> {
  @override
  void initState() {
    super.initState();
    // Subscribe to the entity's changes.
    widget.entity.addListener(_onEntityChanged);
  }

  @override
  void didUpdateWidget(covariant EntityWidgetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the entity instance itself changes, update the listener.
    if (widget.entity != oldWidget.entity) {
      oldWidget.entity.removeListener(_onEntityChanged);
      widget.entity.addListener(_onEntityChanged);
    }
  }

  @override
  void dispose() {
    // Unsubscribe to prevent memory leaks.
    widget.entity.removeListener(_onEntityChanged);
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
    return widget.builder(context, widget.entity);
  }
}
