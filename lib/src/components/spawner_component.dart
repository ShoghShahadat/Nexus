import 'package:nexus/nexus.dart';

/// A component used to control a particle spawning system.
/// It holds data about the spawn rate and timing.
class SpawnerComponent extends Component with SerializableComponent {
  final double spawnRate; // Particles per second
  double timeSinceLastSpawn;

  SpawnerComponent({required this.spawnRate, this.timeSinceLastSpawn = 0.0});

  factory SpawnerComponent.fromJson(Map<String, dynamic> json) {
    return SpawnerComponent(
      spawnRate: (json['spawnRate'] as num).toDouble(),
      timeSinceLastSpawn: (json['timeSinceLastSpawn'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'spawnRate': spawnRate,
        'timeSinceLastSpawn': timeSinceLastSpawn,
      };

  @override
  List<Object?> get props => [spawnRate, timeSinceLastSpawn];
}
