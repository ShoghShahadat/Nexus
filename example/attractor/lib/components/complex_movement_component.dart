import 'dart:math';
import 'package:nexus/nexus.dart';

/// Defines the types of complex movement a particle can have.
enum MovementType {
  SineWave,
  Spiral,
}

/// A component that adds a complex, secondary movement pattern to a particle.
/// Defined locally in the example to showcase extensibility.
class ComplexMovementComponent extends Component with SerializableComponent {
  final MovementType type;
  final double amplitude; // Strength or size of the movement
  final double frequency; // Speed of the movement
  double time; // Internal clock for the movement calculation

  ComplexMovementComponent({
    required this.type,
    required this.amplitude,
    required this.frequency,
    this.time = 0.0,
  });

  /// Creates a component with randomized parameters for unique particle behavior.
  factory ComplexMovementComponent.random() {
    final random = Random();
    return ComplexMovementComponent(
      type: MovementType.values[random.nextInt(MovementType.values.length)],
      amplitude: random.nextDouble() * 50 + 20, // Amplitude between 20 and 70
      frequency: random.nextDouble() * 2 + 1, // Frequency between 1 and 3
    );
  }

  factory ComplexMovementComponent.fromJson(Map<String, dynamic> json) {
    return ComplexMovementComponent(
      type: MovementType.values[json['type'] as int],
      amplitude: (json['amplitude'] as num).toDouble(),
      frequency: (json['frequency'] as num).toDouble(),
      time: (json['time'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type.index,
        'amplitude': amplitude,
        'frequency': frequency,
        'time': time,
      };

  @override
  List<Object?> get props => [type, amplitude, frequency, time];
}
