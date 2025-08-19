import 'package:nexus/src/core/component.dart';

/// A component that stores the velocity of an entity.
///
/// The [PhysicsSystem] uses this component to update the entity's
/// [PositionComponent] in each frame, creating movement.
class VelocityComponent extends Component {
  /// Velocity on the x-axis, in pixels per second.
  double x;

  /// Velocity on the y-axis, in pixels per second.
  double y;

  VelocityComponent({this.x = 0.0, this.y = 0.0});
}
