import 'package:nexus/src/core/component.dart';

/// A component that holds a list of simple string tags.
class TagsComponent extends Component {
  final Set<String> tags;

  TagsComponent(this.tags);

  /// Checks if the entity has a specific tag.
  bool hasTag(String tag) => tags.contains(tag);

  /// Adds a tag.
  void add(String tag) => tags.add(tag);

  /// Removes a tag.
  void remove(String tag) => tags.remove(tag);

  @override
  List<Object?> get props => [tags];
}
