import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A component that holds a list of simple string tags.
class TagsComponent extends Component with SerializableComponent {
  final Set<String> tags;

  TagsComponent(this.tags);

  factory TagsComponent.fromJson(Map<String, dynamic> json) {
    // JSON doesn't have a Set type, so we store as List and convert back.
    final List<String> tagList = List<String>.from(json['tags']);
    return TagsComponent(tagList.toSet());
  }

  @override
  Map<String, dynamic> toJson() => {
        // Convert Set to List for JSON compatibility.
        'tags': tags.toList(),
      };

  /// Checks if the entity has a specific tag.
  bool hasTag(String tag) => tags.contains(tag);

  /// Adds a tag.
  void add(String tag) => tags.add(tag);

  /// Removes a tag.
  void remove(String tag) => tags.remove(tag);

  @override
  List<Object?> get props => [tags];
}
