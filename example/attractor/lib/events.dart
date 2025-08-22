/// An event to notify systems of the current screen dimensions.
class ScreenResizeEvent {
  final double width;
  final double height;
  ScreenResizeEvent(this.width, this.height);
}

/// An event to signal that the game should be reset to its initial state.
class RestartGameEvent {}

/// An event to signal that the core particle simulation should be reset.
class ResetSimulationEvent {}

/// An event fired from the control system to the network system, containing
/// the latest player input (e.g., mouse coordinates).
class SendInputEvent {
  final double x;
  final double y;
  SendInputEvent(this.x, this.y);
}
