/// An event fired from the UI thread to the logic isolate when the user's
/// pointer (mouse or touch) moves.
/// Renamed to NexusPointerMoveEvent to avoid conflict with Flutter's PointerMoveEvent.
class NexusPointerMoveEvent {
  // نام کلاس تغییر یافت
  final double x;
  final double y;

  NexusPointerMoveEvent(this.x, this.y);
}
