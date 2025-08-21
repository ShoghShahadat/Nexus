import 'package:nexus/nexus.dart';

/// An enum representing the screen orientation.
enum ScreenOrientation { portrait, landscape }

/// A serializable component that holds information about the current screen or window.
///
/// This component is typically placed on a central 'root' or 'world_state' entity
/// and is kept updated by the `NexusWidget` on the UI thread.
class ScreenInfoComponent extends Component with SerializableComponent {
  final double width;
  final double height;
  final ScreenOrientation orientation;

  ScreenInfoComponent({
    required this.width,
    required this.height,
    required this.orientation,
  });

  /// Deserializes a component from JSON data.
  factory ScreenInfoComponent.fromJson(Map<String, dynamic> json) {
    return ScreenInfoComponent(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      orientation: ScreenOrientation.values[json['orientation'] as int],
    );
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'orientation': orientation.index,
      };

  @override
  List<Object?> get props => [width, height, orientation];
}
