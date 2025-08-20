import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A simple data component that holds the current integer state of the counter.
/// This component is serializable to be sent from the logic isolate to the UI.
class CounterStateComponent extends Component with SerializableComponent {
  final int value;

  CounterStateComponent(this.value);

  /// Deserializes a component from a JSON map.
  factory CounterStateComponent.fromJson(Map<String, dynamic> json) {
    return CounterStateComponent(json['value'] as int);
  }

  /// Serializes the component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {'value': value};

  @override
  List<Object?> get props => [value];
}
