import 'package:nexus/nexus.dart';

/// An event fired from the UI thread to the logic isolate when an entity
/// is tapped. This is a simple data class to ensure it can be sent
/// across isolate boundaries.
class EntityTapEvent {
  final EntityId id;

  EntityTapEvent(this.id);
}
