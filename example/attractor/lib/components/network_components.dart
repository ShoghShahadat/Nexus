import 'package:nexus/nexus.dart';

/// Identifies an entity as a player in the online game.
class PlayerComponent extends Component with BinaryComponent {
  late int sessionId;
  late bool isLocalPlayer;

  // FIX: Added a default constructor for the factory
  PlayerComponent({int? sessionId, bool? isLocalPlayer})
      : sessionId = sessionId ?? 0,
        isLocalPlayer = isLocalPlayer ?? false;

  @override
  int get typeId => 2; // Unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    sessionId = reader.readInt32();
    isLocalPlayer = reader.readBool();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeInt32(sessionId);
    writer.writeBool(isLocalPlayer);
  }

  @override
  List<Object?> get props => [sessionId, isLocalPlayer];
}

/// A marker component for the entity that is locally controlled.
class ControlledPlayerComponent extends Component {
  @override
  List<Object?> get props => [];
}

/// Holds the current status of the WebSocket connection.
class NetworkStateComponent extends Component {
  final bool isConnected;
  final String statusMessage;

  NetworkStateComponent(
      {this.isConnected = false, this.statusMessage = 'Connecting...'});

  @override
  List<Object?> get props => [isConnected, statusMessage];
}
