import 'package:nexus/nexus.dart';

/// A component to manage interactions for a drawable entity.
/// This component is NOT serializable because it may contain event objects or callbacks.
/// It is used by the logic-side CustomPaintingSystem to attach interaction data
/// to the render packet, which is then used for hit-testing on the UI thread.
class InteractiveComponent extends Component {
  /// If true, this shape can be a target for pointer events.
  final bool isHitTestable;

  /// An optional event to be fired on the event bus upon a tap.
  /// The event can carry any data, including the entity's ID.
  final dynamic onTapEvent;

  /// An optional event to be fired on drag updates.
  final dynamic onDragUpdateEvent;

  // Future additions could include onHover, onDragStart, onDragEnd, etc.

  InteractiveComponent({
    this.isHitTestable = true,
    this.onTapEvent,
    this.onDragUpdateEvent,
  });

  @override
  List<Object?> get props => [isHitTestable, onTapEvent, onDragUpdateEvent];
}
