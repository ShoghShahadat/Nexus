import 'package:nexus/nexus.dart';

/// A data-driven component that holds the state and values of the current application theme.
///
/// This component is typically placed on a central entity (e.g., 'root')
/// and is used by the ThemingSystem to apply styles to other entities.
class ThemeComponent extends Component with SerializableComponent {
  /// The unique identifier for the current theme (e.g., 'dark_mode', 'glassmorphism_light').
  final String id;

  /// A map of style values for the current theme.
  /// Keys are property names (like 'primaryColor'), and values are the corresponding data.
  final Map<String, dynamic> properties;

  ThemeComponent({required this.id, this.properties = const {}});

  /// Deserializes a component from JSON data.
  factory ThemeComponent.fromJson(Map<String, dynamic> json) {
    return ThemeComponent(
      id: json['id'] as String,
      properties: Map<String, dynamic>.from(json['properties']),
    );
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'properties': properties,
      };

  @override
  List<Object?> get props => [id, properties];
}
