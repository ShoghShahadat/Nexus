/// An event fired from the UI thread to the logic isolate when the user's
/// pointer (mouse or touch) moves.
class PointerMoveEvent {
  final double x;
  final double y;

  PointerMoveEvent(this.x, this.y);
}
