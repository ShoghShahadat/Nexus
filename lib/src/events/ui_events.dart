import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// An internal client-side event fired from the Joystick widget.
class JoystickUpdateEvent {
  final Offset vector;
  JoystickUpdateEvent(this.vector);
}

/// An internal client-side event fired from the NexusWidget's KeyboardListener.
class ClientKeyboardEvent {
  final LogicalKeyboardKey key;
  final bool isDown;
  ClientKeyboardEvent(this.key, this.isDown);
}
