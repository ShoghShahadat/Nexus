import 'package:nexus/nexus.dart';

/// A component that holds the description of a shape (number of sides).
/// This makes it safe to be created and managed in a background isolate.
class ShapePathComponent extends Component with SerializableComponent {
  final int sides;

  ShapePathComponent({required this.sides});

  factory ShapePathComponent.fromJson(Map<String, dynamic> json) {
    return ShapePathComponent(
      sides: json['sides'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'sides': sides,
      };

  @override
  List<Object?> get props => [sides];
}
