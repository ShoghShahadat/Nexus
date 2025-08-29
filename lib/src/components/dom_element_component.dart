import 'package:nexus/nexus.dart';

/// Represents a declarative UI element, similar to an HTML DOM node.
/// This component defines the structure and content of a UI element.
///
/// Styling is applied separately via a `StyleSheetComponent`.
/// The hierarchy is defined using `ChildrenComponent` and `ParentComponent`.
class DomElementComponent extends Component with SerializableComponent {
  /// The tag name of the element, e.g., 'div', 'p', 'button', 'h1'.
  /// The `WebUIBuilder` uses this tag to determine which Flutter widget to render.
  final String tag;

  /// A map of attributes for the element, like 'id' and 'class'.
  /// The 'class' attribute is a space-separated list of class names used for styling.
  final Map<String, String> attributes;

  /// The text content of the element, if any.
  final String? text;

  DomElementComponent({
    required this.tag,
    this.attributes = const {},
    this.text,
  });

  /// A convenience getter to extract class names from the 'class' attribute.
  Set<String> get classes {
    final classString = attributes['class'];
    if (classString == null || classString.isEmpty) {
      return {};
    }
    return classString.split(' ').where((c) => c.isNotEmpty).toSet();
  }

  factory DomElementComponent.fromJson(Map<String, dynamic> json) {
    return DomElementComponent(
      tag: json['tag'] as String,
      attributes: Map<String, String>.from(json['attributes']),
      text: json['text'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'tag': tag,
        'attributes': attributes,
        'text': text,
      };

  @override
  List<Object?> get props => [tag, attributes, text];
}
