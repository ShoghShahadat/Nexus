/// An event that is fired when a user selects a new shape to morph into.
/// This event is isolate-safe as it only carries a primitive data type.
class ShapeSelectedEvent {
  /// The number of sides of the shape that was selected.
  final int targetSides;

  ShapeSelectedEvent(this.targetSides);
}
