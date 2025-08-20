import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

/// A component that holds the display-only data for a morphing shape.
///
/// This component is NOT serializable because it holds a Path object. It should
/// only exist on the UI thread, managed by the FlutterRenderingSystem.
class MorphingDisplayComponent extends Component {
  /// The currently interpolated path, calculated by the UI layer.
  final Path currentPath;

  MorphingDisplayComponent({required this.currentPath});

  @override
  List<Object?> get props => [currentPath];
}

/// A component that holds the *description* of a morphing animation.
///
/// This component is isolate-safe and serializable. It is used by the logic
/// systems in the background isolate to manage the state of the animation.
class MorphingLogicComponent extends Component with SerializableComponent {
  final int initialSides;
  final int targetSides;

  MorphingLogicComponent({
    required this.initialSides,
    required this.targetSides,
  });

  factory MorphingLogicComponent.fromJson(Map<String, dynamic> json) {
    return MorphingLogicComponent(
      initialSides: json['initialSides'] as int,
      targetSides: json['targetSides'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'initialSides': initialSides,
        'targetSides': targetSides,
      };

  @override
  List<Object?> get props => [initialSides, targetSides];
}
