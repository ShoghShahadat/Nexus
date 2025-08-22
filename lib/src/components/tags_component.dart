import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/binary_component.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A component that holds a list of simple string tags.
/// Now supports both JSON and Binary serialization.
class TagsComponent extends Component
    with SerializableComponent, BinaryComponent {
  final Set<String> tags;

  TagsComponent(this.tags);

  // --- SerializableComponent (JSON) ---

  factory TagsComponent.fromJson(Map<String, dynamic> json) {
    final List<String> tagList = List<String>.from(json['tags']);
    return TagsComponent(tagList.toSet());
  }

  @override
  Map<String, dynamic> toJson() => {
        'tags': tags.toList(),
      };

  // --- BinaryComponent (Network) ---

  @override
  int get typeId => 5; // Unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    tags.clear();
    final count = reader.readInt32();
    for (int i = 0; i < count; i++) {
      tags.add(reader.readString());
    }
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeInt32(tags.length);
    for (final tag in tags) {
      writer.writeString(tag);
    }
  }

  // --- Logic ---

  /// Checks if the entity has a specific tag.
  bool hasTag(String tag) => tags.contains(tag);

  /// Adds a tag.
  void add(String tag) => tags.add(tag);

  /// Removes a tag.
  void remove(String tag) => tags.remove(tag);

  @override
  List<Object?> get props => [tags];
}
