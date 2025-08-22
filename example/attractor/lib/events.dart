// --- FIX: This file is now cleaned up. ---
// It only contains events specific to the attractor game logic.
// Generic UI events have been moved to the core Nexus library.

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

/// An event fired from the client's control system to the network system,
/// containing the latest directional input vector.
class SendDirectionalInputEvent {
  final double dx;
  final double dy;
  SendDirectionalInputEvent(this.dx, this.dy);
}
