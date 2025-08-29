import 'package:nexus/nexus.dart';

/// An event fired when a specific drawable shape is tapped.
class ShapeTapEvent {
  final EntityId entityId;
  final String shapeType;

  ShapeTapEvent(this.entityId, this.shapeType);
}
