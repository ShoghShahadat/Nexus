import 'package:nexus/nexus.dart';

/// A component that allows an entity to adapt its appearance based on the active application theme.
///
/// This component defines how an entity's visual properties (like background color)
/// should bind to the global theme values stored in the `ThemeComponent`.
class StyleableComponent extends Component with SerializableComponent {
  /// A map that binds visual properties to keys within the `ThemeComponent`.
  ///
  /// Example:
  /// {
  ///   'backgroundColor': 'primaryColor', // This entity's background will use the theme's primary color.
  ///   'shadowColor': 'shadowColor'
  /// }
  final Map<String, String> styleBindings;

  StyleableComponent({this.styleBindings = const {}});

  /// Deserializes a component from JSON data.
  factory StyleableComponent.fromJson(Map<String, dynamic> json) {
    return StyleableComponent(
      styleBindings: Map<String, String>.from(json['styleBindings']),
    );
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {
        'styleBindings': styleBindings,
      };

  @override
  List<Object?> get props => [styleBindings];
}
