import 'package:nexus/nexus.dart';

/// An event fired to trigger an "undo" action on a specific entity.
class UndoEvent {
  final EntityId entityId;

  UndoEvent(this.entityId);
}

/// An event fired to trigger a "redo" action on a specific entity.
class RedoEvent {
  final EntityId entityId;

  RedoEvent(this.entityId);
}
