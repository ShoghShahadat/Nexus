import 'package:nexus/nexus.dart';

/// A component that caches the final, world-space transformation matrix of an entity.
///
/// This component is managed by the TransformSystem and is used to avoid
/// recalculating transformations for entities that have not moved. It also
/// contains a "dirty flag" to signal when the cache needs to be updated.
class GlobalTransformComponent extends Component with SerializableComponent {
  /// The cached transformation data. In a real-world scenario, this would
  /// likely be a Matrix4, but for simplicity and serialization, we'll store
  /// final x, y, scale, and rotation.
  final double x;
  final double y;
  final double scale;
  final double rotation; // in radians

  /// A flag indicating if the transform needs to be recalculated.
  final bool isDirty;

  GlobalTransformComponent({
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isDirty = true,
  });

  factory GlobalTransformComponent.fromJson(Map<String, dynamic> json) {
    return GlobalTransformComponent(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num? ?? 1.0).toDouble(),
      rotation: (json['rotation'] as num? ?? 0.0).toDouble(),
      isDirty: json['isDirty'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'isDirty': isDirty,
      };

  @override
  List<Object?> get props => [x, y, scale, rotation, isDirty];
}
