import 'package:nexus/src/core/component.dart';

/// A component that holds a list of simple string tags.
///
/// Tags are a flexible way to categorize or identify entities without creating
/// many specific component classes. Systems can then query for entities

/// that have a specific tag.
class TagsComponent extends Component {
  final Set<String> tags;

  TagsComponent(this.tags);

  /// Checks if the entity has a specific tag.
  bool hasTag(String tag) => tags.contains(tag);

  /// Adds a tag.
  void add(String tag) => tags.add(tag);

  /// Removes a tag.
  void remove(String tag) => tags.remove(tag);
}
