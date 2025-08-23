// ==============================================================================
// File: lib/components/attractor_component.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A component that marks an entity as an attractor point
//              for the AttractorSystem. This is the core of the old gameplay.
// ==============================================================================
import 'package:nexus/nexus.dart';

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
