import 'package:nexus/nexus.dart';

// --- P2P Relay Events using Network IDs ---

/// An event fired by the "owner" client to broadcast the creation of a new entity.
class RelayNewEntityEvent {
  final String
      networkId; // Use String for consistency (can be session ID or UUID)
  final List<BinaryComponent> components;
  RelayNewEntityEvent(this.networkId, this.components);
}

/// A generic event to relay the state of a specific component to other clients.
class RelayComponentStateEvent {
  final String networkId;
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

class ScreenResizeEvent {
  final double width;
  final double height;
  ScreenResizeEvent(this.width, this.height);
}

class SendDirectionalInputEvent {
  final double dx;
  final double dy;
  SendDirectionalInputEvent(this.dx, this.dy);
}
