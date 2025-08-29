import 'package:nexus/nexus.dart';

/// A serializable marker component that indicates an entity should be rendered
/// by the CustomPaintingSystem. It holds no data itself.
class DrawableComponent extends Component with SerializableComponent {
  DrawableComponent();

  /// Deserializes a component from JSON data.
  factory DrawableComponent.fromJson(Map<String, dynamic> json) {
    return DrawableComponent();
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
