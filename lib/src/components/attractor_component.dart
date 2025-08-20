import 'package:nexus/nexus.dart';

/// A marker component that identifies an entity as an attractor point
/// for the AttractionSystem (e.g., a black hole).
class AttractorComponent extends Component with SerializableComponent {
  final double strength;

  AttractorComponent({this.strength = 1.0});

  factory AttractorComponent.fromJson(Map<String, dynamic> json) {
    return AttractorComponent(
      strength: (json['strength'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'strength': strength};

  @override
  List<Object?> get props => [strength];
}
