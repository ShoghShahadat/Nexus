import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/binary_component.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A component that stores the velocity of an entity.
class VelocityComponent extends Component
    with SerializableComponent, BinaryComponent {
  double x;
  double y;

  VelocityComponent({this.x = 0.0, this.y = 0.0});

  @override
  int get typeId => 4; // Unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    x = reader.readDouble();
    y = reader.readDouble();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeDouble(x);
    writer.writeDouble(y);
  }

  factory VelocityComponent.fromJson(Map<String, dynamic> json) {
    return VelocityComponent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  List<Object?> get props => [x, y];
}
