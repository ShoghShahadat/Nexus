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
