import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/component.dart';

/// A custom component created to hold the path data for a specific shape.
///
/// This demonstrates the extensibility of the ECS architecture, where developers
/// can create any data container they need to drive new features.
class ShapePathComponent extends Component {
  final Path path;

  ShapePathComponent(this.path);
}
