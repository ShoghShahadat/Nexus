import 'package:flutter/widgets.dart';
import 'package:nexus/src/core/component.dart';

/// A component that holds the data for a path morphing animation.
///
/// The [MorphingSystem] uses this data to smoothly transition a shape
/// from an [initialPath] to a [targetPath].
class MorphingComponent extends Component {
  /// The starting shape of the morph.
  final Path initialPath;

  /// The destination shape of the morph.
  final Path targetPath;

  /// The total duration of the morph animation.
  final Duration duration;

  /// The curve to apply to the animation's progress.
  final Curve curve;

  /// The currently interpolated path, calculated by the [MorphingSystem]
  /// each frame. This is the path that should be rendered.
  Path currentPath;

  MorphingComponent({
    required this.initialPath,
    required this.targetPath,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
  }) : currentPath = initialPath;
}
