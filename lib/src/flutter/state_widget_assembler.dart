import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// A specialized widget builder that acts as a state manager or selector.
///
/// It listens for changes on a specific entity, extracts a component of type [T],
/// and then delegates the actual widget building to another [IWidgetBuilder]
/// that is created based on the state of that component.
///
/// This allows for creating dynamic UIs where the structure of the widget tree
/// can change based on the entity's state (e.g., showing a loading indicator,
/// an error message, or the main content).
class StateWidgetAssembler<T extends Component> implements IWidgetBuilder {
  /// A function that creates the appropriate [IWidgetBuilder] based on the
  /// current state of the component [T]. The state can be null if the component
  /// doesn't exist on the entity.
  final IWidgetBuilder Function(T? state) builderProvider;

  StateWidgetAssembler({required this.builderProvider});

  @override
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
  ) {
    // Use AnimatedBuilder to listen for changes on the specific entity.
    // getNotifier provides a dedicated ChangeNotifier for each entity, ensuring
    // that only this widget rebuilds when its specific entity changes.
    return AnimatedBuilder(
      animation: renderingSystem.getNotifier(entityId),
      builder: (context, child) {
        // On each rebuild, get the most recent state of the component from the cache.
        final componentState = renderingSystem.get<T>(entityId);

        // Use the provider function to get the correct builder for the current state.
        // This allows for conditional logic, e.g., if (state == null) return LoadingBuilder();
        final concreteBuilder = builderProvider(componentState);

        // Delegate the actual building process to the selected builder,
        // passing along all the necessary context and IDs. This corrects the
        // "missing_required_argument" errors.
        return concreteBuilder.build(context, renderingSystem, entityId);
      },
    );
  }
}
