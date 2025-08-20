import 'package:nexus/src/core/entity.dart';

/// A data transfer object used to send the state of an entity's components
/// from the background isolate to the main UI thread for rendering.
///
/// This packet contains serialized component data, making it lightweight and
/// efficient for inter-isolate communication.
class RenderPacket {
  final EntityId id;
  final bool isRemoved;

  /// A map where the key is the component's type name (e.g., "PositionComponent")
  /// and the value is the component's serialized JSON data.
  final Map<String, Map<String, dynamic>> components;

  RenderPacket({
    required this.id,
    required this.components,
    this.isRemoved = false,
  });
}
