import 'package:nexus/nexus.dart';

/// A serializable component that creates a generic, typed link between this
/// entity and a target entity.
///
/// This is useful for establishing relationships beyond parent-child, such as
/// a joystick controlling a character, a camera following a player, or an
/// enemy targeting a hero.
class LinkComponent extends Component with SerializableComponent {
  /// The ID of the entity this component is linking to.
  final EntityId targetId;

  /// A string identifier for the type of link (e.g., 'joystick_control', 'camera_follow').
  /// Systems can use this type to apply specific logic.
  final String linkType;

  /// An optional map for storing extra data related to the link,
  /// such as an offset for a following camera.
  final Map<String, dynamic> properties;

  LinkComponent({
    required this.targetId,
    required this.linkType,
    this.properties = const {},
  });

  /// Deserializes a component from JSON data.
  factory LinkComponent.fromJson(Map<String, dynamic> json) {
    return LinkComponent(
      targetId: json['targetId'] as EntityId,
      linkType: json['linkType'] as String,
      properties: Map<String, dynamic>.from(json['properties']),
    );
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {
        'targetId': targetId,
        'linkType': linkType,
        'properties': properties,
      };

  @override
  List<Object?> get props => [targetId, linkType, properties];
}
