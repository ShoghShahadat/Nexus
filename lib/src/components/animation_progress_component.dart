import 'package:nexus/nexus.dart';

/// A component that holds the current progress of an animation.
/// It is serializable so it can be sent from the logic isolate to the UI
/// thread to drive smooth visual transitions.
class AnimationProgressComponent extends Component with SerializableComponent {
  /// The animation's progress, typically a value between 0.0 and 1.0.
  final double progress;

  AnimationProgressComponent(this.progress);

  factory AnimationProgressComponent.fromJson(Map<String, dynamic> json) {
    return AnimationProgressComponent((json['progress'] as num).toDouble());
  }

  @override
  Map<String, dynamic> toJson() => {'progress': progress};

  @override
  List<Object?> get props => [progress];
}
