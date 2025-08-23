import 'package:nexus/nexus.dart';

/// A component that holds the authoritative, unique identifier for an entity
/// across the entire network. This is the key to P2P state synchronization.
class NetworkIdComponent extends Component with BinaryComponent {
  late String networkId;

  NetworkIdComponent({String? networkId}) : networkId = networkId ?? '';

  @override
  int get typeId => 11; // Assigning a new, unique type ID

  @override
  void fromBinary(BinaryReader reader) {
    networkId = reader.readString();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeString(networkId);
  }

  @override
  List<Object?> get props => [networkId];
}
