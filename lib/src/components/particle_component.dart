import 'package:nexus/nexus.dart';

/// A component that holds data specific to a particle entity.
class ParticleComponent extends Component with SerializableComponent {
  double age;
  final double maxAge;
  final int initialColorValue;
  final int finalColorValue;

  ParticleComponent({
    this.age = 0.0,
    required this.maxAge,
    required this.initialColorValue,
    required this.finalColorValue,
  });

  factory ParticleComponent.fromJson(Map<String, dynamic> json) {
    return ParticleComponent(
      age: (json['age'] as num).toDouble(),
      maxAge: (json['maxAge'] as num).toDouble(),
      initialColorValue: json['initialColorValue'] as int,
      finalColorValue: json['finalColorValue'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'age': age,
        'maxAge': maxAge,
        'initialColorValue': initialColorValue,
        'finalColorValue': finalColorValue,
      };

  @override
  List<Object?> get props => [age, maxAge, initialColorValue, finalColorValue];
}
