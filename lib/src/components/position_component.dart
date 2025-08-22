import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';
import 'package:nexus/src/core/serialization/net_component.dart';
// CRITICAL FIX: Add this import for the generated part file to use.
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';

part 'position_component.g.dart';

/// A component that stores the 2D position and size of an entity.
@NetComponent(1) // Mark for binary serialization with a unique type ID.
class PositionComponent extends Component with SerializableComponent {
  final double x;
  final double y;
  final double width;
  final double height;
  final double scale;

  PositionComponent({
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.scale = 1.0,
  });

  factory PositionComponent.fromJson(Map<String, dynamic> json) {
    return PositionComponent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
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
