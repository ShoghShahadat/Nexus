import 'package:nexus/nexus.dart';

// --- NEW: P2P Relay Events ---

/// An event fired by the "owner" client to broadcast the creation of a new entity.
class RelayNewEntityEvent {
  final int networkId; // The entity ID generated on the owner's client
  final List<BinaryComponent> components;
  RelayNewEntityEvent(this.networkId, this.components);
}

/// A generic event to relay the state of a specific component to other clients.
class RelayComponentStateEvent {
  final int networkId;
  final BinaryComponent component;
  RelayComponentStateEvent(this.networkId, this.component);
}

/// An event to relay simple, named game events (like game over) to other clients.
class RelayGameEvent {
  final String eventName;
  final Map<String, dynamic> data;
  RelayGameEvent(this.eventName, {this.data = const {}});
}

// --- Original Events ---

/// An event to notify systems of the current screen dimensions.
class ScreenResizeEvent {
  final double width;
  final double height;
  ScreenResizeEvent(this.width, this.height);
}

/// An event fired from the client's control system to send its input.
class SendDirectionalInputEvent {
  final double dx;
  final double dy;
  SendDirectionalInputEvent(this.dx, this.dy);
}
