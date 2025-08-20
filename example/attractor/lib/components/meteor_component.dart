import 'package:nexus/nexus.dart';

/// A component that marks an entity as a meteor and tracks its burn-up state.
/// Defined locally in the example to showcase extensibility.
class MeteorComponent extends Component with SerializableComponent {
  /// The remaining "health" of the meteor. It burns away over time.
  double health;

  MeteorComponent({this.health = 1.0}); // Starts with full health

  factory MeteorComponent.fromJson(Map<String, dynamic> json) {
    return MeteorComponent(
      health: (json['health'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'health': health};

  @override
  List<Object?> get props => [health];
}
