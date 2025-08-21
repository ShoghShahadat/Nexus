import 'package:nexus/nexus.dart';

/// A marker component that identifies an entity as a health orb.
class HealthOrbComponent extends Component with SerializableComponent {
  HealthOrbComponent();

  factory HealthOrbComponent.fromJson(Map<String, dynamic> json) {
    return HealthOrbComponent();
  }

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
