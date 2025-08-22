import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_component.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';

/// Identifies an entity as a player in the online game.
class PlayerComponent extends Component with BinaryComponent {
  /// The unique session ID assigned by the server.
  int sessionId;

  /// A flag indicating if this is the player controlled by this client.
  bool isLocalPlayer;

  PlayerComponent({this.sessionId = 0, this.isLocalPlayer = false});

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
