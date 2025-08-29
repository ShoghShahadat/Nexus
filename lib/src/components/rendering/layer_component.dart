import 'package:nexus/nexus.dart';

/// A serializable component that defines the rendering order (z-index)
/// for a drawable entity. Higher numbers are drawn on top.
class LayerComponent extends Component with SerializableComponent {
  final int zIndex;

  LayerComponent(this.zIndex);

  /// Deserializes a component from JSON data.
  factory LayerComponent.fromJson(Map<String, dynamic> json) {
    return LayerComponent(json['zIndex'] as int);
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {'zIndex': zIndex};

  @override
  List<Object?> get props => [zIndex];
}
