// FILE: lib/src/events/component_events.dart
// (English comments for code clarity)
// NEW FILE: Defines core events related to component lifecycle.

import 'package:nexus/nexus.dart';

/// An event fired by the NexusWorld whenever a component is added to an entity
/// or an existing component is replaced with a new instance.
///
/// This is a generic event, allowing systems to listen for updates to specific
/// component types, e.g., `listen<ComponentUpdatedEvent<PositionComponent>>(...)`.
class ComponentUpdatedEvent<T extends Component> {
  /// The ID of the entity that was updated.
  final EntityId entityId;

  /// The new instance of the component that was added or updated.
  final T component;

  ComponentUpdatedEvent({required this.entityId, required this.component});
}
