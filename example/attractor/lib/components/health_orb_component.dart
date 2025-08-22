import 'package:nexus/nexus.dart';

/// A marker component that identifies an entity as a health orb.
/// Now supports binary serialization for network transfer.
class HealthOrbComponent extends Component
    with SerializableComponent, BinaryComponent {
  HealthOrbComponent();

  // --- SerializableComponent (JSON) ---
  factory HealthOrbComponent.fromJson(Map<String, dynamic> json) {
    return HealthOrbComponent();
  }

  @override
  Map<String, dynamic> toJson() => {};

  // --- BinaryComponent (Network) ---
  @override
  int get typeId => 7; // Unique network ID

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
