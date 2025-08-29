// File: lib/src/flutter/widget_builder.dart

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// Defines the contract for any class that can build a widget for an entity.
abstract class IWidgetBuilder {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  );
}

/// Defines a builder for a specific part of a widget (e.g., the child of a button).
abstract class IPartBuilder<T extends Component> {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  );
}

/// Defines a builder for the outer "shell" of a widget (e.g., the button's frame).
abstract class IWidgetShellBuilder<V> {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
    Widget child, // The part built by the IPartBuilder
  );
}

/// Defines a builder for a specific state of a stateful widget.
abstract class IStateWidgetBuilder<S, C extends Component> {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
    C stateComponent,
  );
}
