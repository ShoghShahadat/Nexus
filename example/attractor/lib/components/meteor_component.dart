import 'package:nexus/nexus.dart';

/// A component that marks an entity as a meteor.
/// Now supports binary serialization for network transfer.
class MeteorComponent extends Component
    with SerializableComponent, BinaryComponent {
  MeteorComponent();

  // --- SerializableComponent (JSON) ---
  factory MeteorComponent.fromJson(Map<String, dynamic> json) {
    return MeteorComponent();
  }

  @override
  Map<String, dynamic> toJson() => {};

  // --- BinaryComponent (Network) ---
  @override
  int get typeId => 6; // Unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    // No data to read for a marker component
  }

  @override
  void toBinary(BinaryWriter writer) {
    // No data to write for a marker component
  }

  @override
  List<Object?> get props => [];
}
