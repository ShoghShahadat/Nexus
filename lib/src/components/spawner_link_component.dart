import 'package:nexus/nexus.dart';

/// A component that links a spawner to another entity's position.
/// This allows particles to be emitted from a moving target.
class SpawnerLinkComponent extends Component with SerializableComponent {
  /// The tag of the entity whose position should be used for spawning.
  final String targetTag;

  SpawnerLinkComponent({required this.targetTag});

  factory SpawnerLinkComponent.fromJson(Map<String, dynamic> json) {
    return SpawnerLinkComponent(targetTag: json['targetTag'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'targetTag': targetTag};

  @override
  List<Object?> get props => [targetTag];
}
