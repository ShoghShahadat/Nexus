import 'package:nexus/nexus.dart';

/// A component that marks a particle for explosion and tracks its animation state.
/// This component is defined locally within the example project to demonstrate extensibility.
class ExplodingParticleComponent extends Component with SerializableComponent {
  /// The progress of the explosion animation, from 0.0 to 1.0.
  final double progress;

  ExplodingParticleComponent({this.progress = 0.0});

  factory ExplodingParticleComponent.fromJson(Map<String, dynamic> json) {
    return ExplodingParticleComponent(
      progress: (json['progress'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'progress': progress};

  @override
  List<Object?> get props => [progress];
}
