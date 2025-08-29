import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

/// Defines the contract for a builder that renders a specific state
/// of a feature or component.
///
/// [S] is the Enum type that represents the different states (e.g., ApiStatus).
/// [C] is the type of the component that holds the state value.
abstract class IStateWidgetBuilder<S extends Enum, C extends Component> {
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
    C stateComponent, // Pass the state component directly for convenience
  );
}
