import 'package:nexus/nexus.dart';

/// Identifies an entity as a player in the online game.
class PlayerComponent extends Component with BinaryComponent {
  // --- FIX: Changed sessionId from int to String to match the server. ---
  // --- اصلاح: نوع sessionId از int به String تغییر کرد تا با سرور مطابقت داشته باشد. ---
  late String sessionId;
  late bool isLocalPlayer;

  // --- FIX: Updated the constructor to handle a String sessionId. ---
  // --- اصلاح: سازنده برای مدیریت sessionId از نوع String به‌روزرسانی شد. ---
  PlayerComponent({String? sessionId, bool? isLocalPlayer})
      : sessionId = sessionId ?? '',
        isLocalPlayer = isLocalPlayer ?? false;

  @override
  int get typeId => 2; // Unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    // --- FIX: Now correctly reads a string from the binary stream. ---
    // --- اصلاح: اکنون به درستی یک رشته را از جریان باینری می‌خواند. ---
    sessionId = reader.readString();
    isLocalPlayer = reader.readBool();
  }

  @override
  void toBinary(BinaryWriter writer) {
    // --- FIX: Now correctly writes the string to the binary stream. ---
    // --- اصلاح: اکنون به درستی رشته را در جریان باینری می‌نویسد. ---
    writer.writeString(sessionId);
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
