import 'package:nexus/nexus.dart';

/// Identifies an entity as a player in the online game.
class PlayerComponent extends Component with BinaryComponent {
  late String sessionId;
  late bool isLocalPlayer;
  // --- NEW: Added isHost flag. ---
  // --- جدید: فلگ isHost اضافه شد. ---
  late bool isHost;

  PlayerComponent({
    String? sessionId,
    bool? isLocalPlayer,
    bool? isHost,
  })  : sessionId = sessionId ?? '',
        isLocalPlayer = isLocalPlayer ?? false,
        isHost = isHost ?? false;

  @override
  int get typeId => 2; // Unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    sessionId = reader.readString();
    isLocalPlayer = reader.readBool();
    isHost = reader.readBool();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeString(sessionId);
    writer.writeBool(isLocalPlayer);
    writer.writeBool(isHost);
  }

  @override
  List<Object?> get props => [sessionId, isLocalPlayer, isHost];
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
