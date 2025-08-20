import 'package:nexus/src/core/component.dart';

/// A component that stores the 2D position and size of an entity.
class PositionComponent extends Component {
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

  @override
  List<Object?> get props => [x, y, width, height, scale];
}
