import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/component.dart';

/// A custom component created to hold the path data for a specific shape.
class ShapePathComponent extends Component {
  final Path path;

  ShapePathComponent(this.path);

  @override
  List<Object?> get props => [path];
}
