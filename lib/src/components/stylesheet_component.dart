import 'package:nexus/nexus.dart';

/// Represents a stylesheet, similar to a CSS file in web development.
///
/// This component holds a map of style rules that are applied to entities
/// with a `DomElementComponent` by the `WebUIBuilder`.
/// It is typically attached to a root entity.
class StyleSheetComponent extends Component with SerializableComponent {
  /// The map of style rules.
  /// Keys are selectors (e.g., '.container', 'button', '#header').
  /// Values are maps of CSS-like properties (e.g., {'background-color': '#FFFFFF', 'padding': '16px'}).
  final Map<String, Map<String, dynamic>> styles;

  StyleSheetComponent({this.styles = const {}});

  factory StyleSheetComponent.fromJson(Map<String, dynamic> json) {
    // Ensure nested maps are correctly typed during deserialization.
    final styleMap = (json['styles'] as Map).map(
      (key, value) => MapEntry(
        key as String,
        Map<String, dynamic>.from(value as Map),
      ),
    );
    return StyleSheetComponent(styles: styleMap);
  }

  @override
  Map<String, dynamic> toJson() => {'styles': styles};

  @override
  List<Object?> get props => [styles];
}
