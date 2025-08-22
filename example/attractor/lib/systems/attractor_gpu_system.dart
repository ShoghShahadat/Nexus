import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:nexus/nexus.dart';
import '../events.dart';

// The Dart data structure for a single particle.
class ParticleData {
  final Vec2 position;
  final Vec2 velocity;
  double age;
  final double maxAge;
  final double initialSize;
  // Add a seed property for randomness in the shader
  double seed;

  ParticleData({
    required this.position,
    required this.velocity,
    this.age = 0.0,
    required this.maxAge,
    required this.initialSize,
    this.seed = 0.0,
  });
}

// A simple 2D vector class.
class Vec2 with EquatableMixin {
  double x, y;
  Vec2(this.x, this.y);
  @override
  List<Object?> get props => [x, y];
}

// A class to represent the parameters passed to the shader.
class SimParams {
  final double deltaTime;
  final double attractorX;
  final double attractorY;
  final double attractorStrength;

  SimParams(
      {required this.deltaTime,
      required this.attractorX,
      required this.attractorY,
      required this.attractorStrength});
}

class AttractorGpuSystem extends GpuSystem<ParticleData> {
  final int particleCount;
  final Random _random = Random();
  late List<ParticleData> _particleObjects;

  // =======================================================================
  // --- USER'S CODE: THE FINAL VISION ---
  // The user writes their logic in a pure Dart function like this.
  // They don't need to know about WGSL or strings.
  // --- کد کاربر: چشم‌انداز نهایی ---
  // کاربر منطق خود را در یک تابع خالص Dart مانند این می‌نویسد.
  // نیازی به دانستن WGSL یا رشته‌ها نیست.
  // =======================================================================
  void gpuLogic(ParticleData p, SimParams params) {
    // This Dart code is the "source of truth". The build_runner would
    // analyze this function to generate the WGSL code below.
    // Note: This function is NOT executed by the CPU. It's only for transpilation.

    if (p.age >= p.maxAge) {
      p.position.x = params.attractorX;
      p.position.y = params.attractorY;

      // Pseudo-random logic using seed
      final seed = p.seed + (params.deltaTime * 1000.0);
      final angle = (sin(seed) * 43758.5453).abs() % (2 * 3.14159);
      final speed = 50.0 + (sin(seed * 2.0) * 43758.5453).abs() % 100.0;
      p.velocity.x = cos(angle) * speed;
      p.velocity.y = sin(angle) * speed;
      p.age = 0.0;
      p.seed += 1.0;
    }

    final dirX = params.attractorX - p.position.x;
    final dirY = params.attractorY - p.position.y;
    final distSq = (dirX * dirX) + (dirY * dirY);

    if (distSq > 1.0) {
      final dist = sqrt(distSq);
      final force = params.attractorStrength * 1000.0 / distSq;
      p.velocity.x += (dirX / dist) * force * params.deltaTime;
      p.velocity.y += (dirY / dist) * force * params.deltaTime;
    }

    // Drag
    p.velocity.x *= (1.0 - (0.1 * params.deltaTime));
    p.velocity.y *= (1.0 - (0.1 * params.deltaTime));

    p.position.x += p.velocity.x * params.deltaTime;
    p.position.y += p.velocity.y * params.deltaTime;
    p.age += params.deltaTime;
  }

  // =======================================================================
  // --- GENERATED CODE (The Magic Behind the Scenes) ---
  // In a real project, a build tool would generate the content of this
  // getter from the `gpuLogic` function above. The user never touches this.
  // --- کد تولید شده (جادوی پشت صحنه) ---
  // در یک پروژه واقعی، یک ابزار ساخت، محتوای این getter را از تابع
  // `gpuLogic` بالا تولید می‌کند. کاربر هرگز به این دست نمی‌زند.
  // =======================================================================
  @override
  String get wgslSourceCode => '''
    struct Particle {
        pos: vec2<f32>,
        vel: vec2<f32>,
        age: f32,
        max_age: f32,
        initial_size: f32,
        seed: f32,
    };

    struct SimParams {
        delta_time: f32,
        attractor_x: f32,
        attractor_y: f32,
        attractor_strength: f32,
    };

    @group(0) @binding(1)
    var<uniform> params: SimParams;

    @group(0) @binding(0)
    var<storage, read_write> particles: array<Particle>;

    fn hash(n: f32) -> f32 {
        return fract(sin(n) * 43758.5453123);
    }

    @compute @workgroup_size(256)
    fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
        let index = global_id.x;
        let array_len = arrayLength(&particles);
        if (index >= array_len) { return; }
        var p = particles[index];

        if (p.age >= p.max_age) {
            p.pos = vec2<f32>(params.attractor_x, params.attractor_y);
            let seed = p.seed + (params.delta_time * 1000.0);
            let angle = hash(seed) * 2.0 * 3.14159;
            let speed = 50.0 + hash(seed * 2.0) * 100.0;
            p.vel = vec2<f32>(cos(angle) * speed, sin(angle) * speed);
            p.age = 0.0;
            p.seed = p.seed + 1.0;
        }

        let attractor_pos = vec2<f32>(params.attractor_x, params.attractor_y);
        let dir = attractor_pos - p.pos;
        let dist_sq = dot(dir, dir);

        if (dist_sq > 1.0) {
            let dist = sqrt(dist_sq);
            let force = params.attractor_strength * 1000.0 / dist_sq;
            p.vel = p.vel + (dir / dist) * force * params.delta_time;
        }
        
        p.vel = p.vel * (1.0 - (0.1 * params.delta_time));
        p.pos = p.pos + p.vel * params.delta_time;
        p.age = p.age + params.delta_time;

        particles[index] = p;
    }
  ''';

  // --- System Implementation Details ---
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
      seed: _random.nextDouble() * 1000.0,
    );
  }

  @override
  Float32List flattenData(List<ParticleData> data) {
    if (data.isEmpty) return Float32List(0);
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
      list[baseIndex + 7] = p.seed;
    }
    return list;
  }
}
