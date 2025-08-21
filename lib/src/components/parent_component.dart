import 'package:nexus/nexus.dart';

/// A serializable component that establishes a parent-child relationship
/// between entities.
///
/// When an entity has this component, its position will be relative to the
/// position of its parent entity. This is managed by the `TransformSystem`.
class ParentComponent extends Component with SerializableComponent {
  /// The ID of the parent entity.
  final EntityId parentId;

  ParentComponent(this.parentId);

  /// Deserializes a component from JSON data.
  factory ParentComponent.fromJson(Map<String, dynamic> json) {
    return ParentComponent(json['parentId'] as EntityId);
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {'parentId': parentId};

  @override
  List<Object?> get props => [parentId];
}
