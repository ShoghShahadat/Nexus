import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A component that stores the velocity of an entity.
class VelocityComponent extends Component with SerializableComponent {
  /// Velocity on the x-axis, in pixels per second.
  double x;

  /// Velocity on the y-axis, in pixels per second.
  double y;

  VelocityComponent({this.x = 0.0, this.y = 0.0});

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
