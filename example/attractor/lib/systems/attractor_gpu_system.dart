import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:nexus/nexus.dart';
import '../events.dart';

// The Dart data structure for a single particle.
// The GpuSystem will use this to understand the data layout.
class ParticleData {
  final Vec2 position;
  final Vec2 velocity;
  double age;
  final double maxAge;
  final double initialSize;

  ParticleData({
    required this.position,
    required this.velocity,
    this.age = 0.0,
    required this.maxAge,
    required this.initialSize,
  });
}

// A simple 2D vector class.
class Vec2 with EquatableMixin {
  double x, y;
  Vec2(this.x, this.y);
  @override
  List<Object?> get props => [x, y];
}

class AttractorGpuSystem extends GpuSystem<ParticleData> {
  final int particleCount;
  final Random _random = Random();
  late List<ParticleData> _particleObjects;

  // --- THE NEW ARCHITECTURE ---
  // Instead of a pre-compiled shader, we define the GPU logic
  // right here in Dart! The GpuSystem will transpile this.
  // --- معماری جدید ---
  // به جای یک شیدر از پیش کامپایل شده، ما منطق GPU را
  // دقیقاً اینجا در Dart تعریف می‌کنیم! GpuSystem این را ترجمه خواهد کرد.
  @override
  String get gpuLogicSourceCode => '''
    void gpuLogic(Particle p, SimParams params) {
      if (p.age >= p.max_age) {
          p.pos.x = params.attractor_x;
          p.pos.y = params.attractor_y;
          
          let seed = p.seed + (params.delta_time * 1000.0);
          let angle = hash(seed) * 2.0 * 3.14159;
          let speed = 50.0 + hash(seed * 2.0) * 100.0;
          p.vel.x = cos(angle) * speed;
          p.vel.y = sin(angle) * speed;
          p.age = 0.0;
          p.seed = p.seed + 1.0; // Change seed for next respawn
      }

      let attractor_pos_x = params.attractor_x;
      let attractor_pos_y = params.attractor_y;
      
      let dir_x = attractor_pos_x - p.pos.x;
      let dir_y = attractor_pos_y - p.pos.y;
      
      let dist_sq = (dir_x * dir_x) + (dir_y * dir_y);

      if (dist_sq > 1.0) {
          let dist = sqrt(dist_sq);
          let force = params.attractor_strength * 1000.0 / dist_sq;
          p.vel.x = p.vel.x + (dir_x / dist) * force * params.delta_time;
          p.vel.y = p.vel.y + (dir_y / dist) * force * params.delta_time;
      }
      
      p.pos.x = p.pos.x + p.vel.x * params.delta_time;
      p.pos.y = p.pos.y + p.vel.y * params.delta_time;
      p.age = p.age + params.delta_time;
    }
  ''';

  AttractorGpuSystem({this.particleCount = 500});

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ResetSimulationEvent>((_) => reinitializeData());
  }

  @override
  List<ParticleData> initializeData() {
    _particleObjects = List.generate(particleCount, (i) {
      final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
      final w = screenInfo?.width ?? 400;
      final h = screenInfo?.height ?? 800;
      return _createParticle(w / 2, h * 0.8);
    });
    return _particleObjects;
  }

  ParticleData _createParticle(double x, double y) {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 150 + 50;
    return ParticleData(
      position: Vec2(x, y),
      velocity: Vec2(cos(angle) * speed, sin(angle) * speed),
      age: 0.0,
      maxAge: _random.nextDouble() * 3 + 2,
      initialSize: _random.nextDouble() * 2.0 + 1.0,
    );
  }

  @override
  Float32List flattenData(List<ParticleData> data) {
    if (data.isEmpty) return Float32List(0);
    // Stride is now 8: pos(2), vel(2), age(1), max_age(1), initial_size(1), seed(1)
    final list = Float32List(data.length * 8);
    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      final baseIndex = i * 8;
      list[baseIndex + 0] = p.position.x;
      list[baseIndex + 1] = p.position.y;
      list[baseIndex + 2] = p.velocity.x;
      list[baseIndex + 3] = p.velocity.y;
      list[baseIndex + 4] = p.age;
      list[baseIndex + 5] = p.maxAge;
      list[baseIndex + 6] = p.initialSize;
      list[baseIndex + 7] = _random.nextDouble() * 1000.0; // Initial seed
    }
    return list;
  }
}
