import 'package:nexus/nexus.dart';

/// A component used to control a particle spawning system.
/// It holds data about the spawn rate and timing.
/// کامپوننتی برای کنترل سیستم تولید ذرات که داده‌های مربوط به نرخ و زمان تولید را نگهداری می‌کند.
/// Renamed to avoid conflict with the gameplay SpawnerComponent.
/// برای جلوگیری از تداخل با SpawnerComponent گیم‌پلی، تغییر نام داده شد.
class ParticleSpawnerComponent extends Component with SerializableComponent {
  final double spawnRate; // Particles per second
  double timeSinceLastSpawn;

  ParticleSpawnerComponent(
      {required this.spawnRate, this.timeSinceLastSpawn = 0.0});

  factory ParticleSpawnerComponent.fromJson(Map<String, dynamic> json) {
    return ParticleSpawnerComponent(
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
