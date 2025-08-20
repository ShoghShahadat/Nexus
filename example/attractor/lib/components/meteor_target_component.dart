import 'package:nexus/nexus.dart';

/// Defines the behavior of a meteor, whether it has a random trajectory
/// or is homing in on a specific target.
class MeteorTargetComponent extends Component with SerializableComponent {
  /// The ID of the entity to target. If null, the meteor has a random trajectory.
  final EntityId? targetId;

  MeteorTargetComponent({this.targetId});

  factory MeteorTargetComponent.fromJson(Map<String, dynamic> json) {
    return MeteorTargetComponent(
      targetId: json['targetId'] as EntityId?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'targetId': targetId};

  @override
  List<Object?> get props => [targetId];
}
