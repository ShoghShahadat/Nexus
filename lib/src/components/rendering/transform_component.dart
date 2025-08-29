import 'package:nexus/nexus.dart';

/// A serializable component that holds 2D transformation data for a drawable entity.
class TransformComponent extends Component with SerializableComponent {
  final double x;
  final double y;
  final double scale;
  final double rotation; // in radians

  TransformComponent({
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  factory TransformComponent.fromJson(Map<String, dynamic> json) {
    return TransformComponent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
      rotation: (json['rotation'] as num? ?? 0.0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
      };

  @override
  List<Object?> get props => [x, y, scale, rotation];
}
