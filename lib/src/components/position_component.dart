// FILE: lib/src/components/position_component.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added the missing `copyWith` method for easier, immutable updates.

import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/binary_component.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A component that stores the 2D position and size of an entity.
class PositionComponent extends Component
    with SerializableComponent, BinaryComponent {
  double x;
  double y;
  double width;
  double height;
  double scale;

  PositionComponent({
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.scale = 1.0,
  });

  /// Creates a new PositionComponent with updated values.
  PositionComponent copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? scale,
  }) {
    return PositionComponent(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
    );
  }

  // --- BinaryComponent Implementation ---

  @override
  int get typeId => 1;

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeDouble(x);
    writer.writeDouble(y);
    writer.writeDouble(width);
    writer.writeDouble(height);
    writer.writeDouble(scale);
  }

  @override
  void fromBinary(BinaryReader reader) {
    x = reader.readDouble();
    y = reader.readDouble();
    width = reader.readDouble();
    height = reader.readDouble();
    scale = reader.readDouble();
  }

  // --- SerializableComponent (for JSON) Implementation ---

  factory PositionComponent.fromJson(Map<String, dynamic> json) {
    return PositionComponent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'scale': scale,
      };

  @override
  List<Object?> get props => [x, y, width, height, scale];
}
