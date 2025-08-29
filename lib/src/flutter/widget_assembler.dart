import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

// --- BASE INTERFACE ---

/// Defines the contract for a specialized, self-contained widget builder.
abstract class IWidgetBuilder {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  );
}

// --- STATE-BASED ASSEMBLER ---

/// A specialized builder that needs access to the state of a component [T]
/// to render its UI.
abstract class IStateWidgetBuilder<T extends Component>
    implements IWidgetBuilder {
  /// *** FINAL FIX: Provide a concrete implementation for the base build method. ***
  /// This implementation fetches the required state component from the rendering
  /// system and then delegates the actual work to the abstract `buildWithState` method.
  /// This way, concrete classes only need to implement `buildWithState`.
  @override
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  ) {
    final state = renderingSystem.get<T>(entityId);
    // It's crucial to handle the case where the state might not exist yet.
    if (state == null) {
      // Returning an empty box is a safe default if state is not ready.
      return const SizedBox.shrink();
    }
    return buildWithState(context, renderingSystem, entityId, state);
  }

  /// The primary build method for a stateful builder, providing direct access
  /// to the component's state. Concrete classes MUST implement this.
  Widget buildWithState(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
    T state,
  );
}

/// A widget builder that selects and uses another builder based on the state
/// of a specific component [T].
class StateWidgetAssembler<T extends Component> implements IWidgetBuilder {
  final IWidgetBuilder Function(T? state) builderProvider;

  StateWidgetAssembler({required this.builderProvider});

  @override
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  ) {
    return EntityWidgetBuilder(
      renderingSystem: renderingSystem,
      entityId: entityId,
      builder: (context) {
        final componentState = renderingSystem.get<T>(entityId);
        final concreteBuilder = builderProvider(componentState);
        return concreteBuilder.build(context, renderingSystem, entityId);
      },
    );
  }
}

// --- VARIANT-BASED ASSEMBLER (For Buttons, etc.) ---

/// Builds the inner child of a complex widget (e.g., the Text and Icon of a Button).
abstract class IPartBuilder<T extends Component> {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  );
}

/// Builds the outer shell of a complex widget and wraps the child provided by a PartBuilder.
/// (e.g., the ElevatedButton or OutlinedButton shell).
abstract class IWidgetShellBuilder<V> {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
    Widget child,
  );
}

/// Assembles a widget from multiple parts based on a variant extracted from a component.
/// Ideal for building complex, multi-state components like buttons.
class WidgetAssembler<V, T extends Component> implements IWidgetBuilder {
  final IPartBuilder partBuilder;
  final V Function(T component) variantExtractor;
  final Map<V, IWidgetShellBuilder<V>> shellBuilders;

  WidgetAssembler({
    required this.partBuilder,
    required this.variantExtractor,
    required this.shellBuilders,
  });

  @override
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  ) {
    return EntityWidgetBuilder(
      renderingSystem: renderingSystem,
      entityId: entityId,
      builder: (context) {
        final component = renderingSystem.get<T>(entityId);
        if (component == null) return const SizedBox.shrink();

        final variant = variantExtractor(component);
        final shellBuilder = shellBuilders[variant];
        if (shellBuilder == null) return const SizedBox.shrink();

        final child = partBuilder.build(context, renderingSystem, entityId);
        return shellBuilder.build(context, renderingSystem, entityId, child);
      },
    );
  }
}
