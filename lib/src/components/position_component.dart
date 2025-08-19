import 'package:nexus/src/core/component.dart';

/// A component that stores the 2D position and size of an entity.
///
/// This is a fundamental component used by rendering and input systems
/// to determine where an entity is on the screen and what its boundaries are.
class PositionComponent extends Component {
  double x;
  double y;
  double width;
  double height;

  PositionComponent({
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.0,
    this.height = 0.0,
  });
}
