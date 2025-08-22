import 'dart:math';
import 'dart:typed_data';

import 'package:nexus/nexus.dart';
import '../events.dart';

// A simple 2D vector class for our particle data structure.
class Vec2 with EquatableMixin {
  double x, y;
  Vec2(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

// The data structure for a single particle.
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

// A component to hold global data (uniforms) for the GPU simulation.
class GpuUniformsComponent extends Component {
  final double attractorX;
  final double attractorY;
  final double attractorStrength;
  final double screenWidth;
  final double screenHeight;

  GpuUniformsComponent({
    this.attractorX = 0.0,
    this.attractorY = 0.0,
    this.attractorStrength = 1.0,
    this.screenWidth = 400.0,
    this.screenHeight = 800.0,
  });

  @override
  List<Object?> get props =>
      [attractorX, attractorY, attractorStrength, screenWidth, screenHeight];
}

class AttractorGpuSystem extends GpuSystem<ParticleData> {
  final int particleCount;
  final Random _random = Random();
  late List<ParticleData> _particleObjects;

  AttractorGpuSystem({this.particleCount = 500});

  // --- FIX: Implemented the missing abstract getter 'wgslSourceCode' ---
  // This provides the GPU shader code that corresponds to the logic in the
  // other (transpiled) attractor system.
  @override
  String get wgslSourceCode => r'''
struct Particle {
    pos: vec2<f32>,
    vel: vec2<f32>,
    age: f32,
    max_age: f32,
    initial_size: f32,
    padding: f32,
};

struct SimParams {
    delta_time: f32,
    attractor_x: f32,
    attractor_y: f32,
    attractor_strength: f32,
};

@group(0) @binding(0) var<storage, read_write> particles: array<Particle>;
@group(0) @binding(1) var<uniform> params: SimParams;

@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let index = global_id.x;
    var p = particles[index];

    if (p.age >= p.max_age) {
        p.pos.x = params.attractor_x;
        p.pos.y = params.attractor_y;

        let angle = (p.initial_size * 1000.0) * 2.0 * 3.14159;
        let speed = 50.0 + (p.initial_size * 50.0);
        p.vel.x = cos(angle) * speed;
        p.vel.y = sin(angle) * speed;
        p.age = 0.0;
    }

    let dir = vec2<f32>(params.attractor_x - p.pos.x, params.attractor_y - p.pos.y);
    let dist_sq = dot(dir, dir);

    if (dist_sq > 1.0) {
        let dist = sqrt(dist_sq);
        let force = params.attractor_strength * 1000.0 / dist_sq;
        p.vel = p.vel + (dir / dist) * force * params.delta_time;
    }

    p.pos = p.pos + p.vel * params.delta_time;
    p.age = p.age + params.delta_time;

    particles[index] = p;
}
''';

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
  void gpuLogic(ParticleData p, GpuKernelContext ctx) {
    // This logic is a simple Dart equivalent of the shader for CPU fallback.
    // It's not used when the GPU is running correctly.
    final attractor = world.rootEntity.get<GpuUniformsComponent>()!;
    final attractorPos = Vec2(attractor.attractorX, attractor.attractorY);

    final dirX = attractorPos.x - p.position.x;
    final dirY = attractorPos.y - p.position.y;
    final distSq = (dirX * dirX) + (dirY * dirY);

    if (distSq > 1.0) {
      final dist = sqrt(distSq);
      final force = attractor.attractorStrength * 1000.0 / distSq;
      p.velocity.x += (dirX / dist) * force * ctx.deltaTime;
      p.velocity.y += (dirY / dist) * force * ctx.deltaTime;
    }

    p.position.x += p.velocity.x * ctx.deltaTime;
    p.position.y += p.velocity.y * ctx.deltaTime;
    p.age += ctx.deltaTime;

    if (p.age >= p.maxAge) {
      final newParticle = _createParticle(attractorPos.x, attractorPos.y);
      p.position.x = newParticle.position.x;
      p.position.y = newParticle.position.y;
      p.velocity.x = newParticle.velocity.x;
      p.velocity.y = newParticle.velocity.y;
      p.age = 0.0;
    }
  }

  @override
  Float32List flattenData(List<ParticleData> data) {
    if (data.isEmpty) return Float32List(0);
    // Stride is 8 to account for memory padding in the shader
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
      list[baseIndex + 7] = 0.0; // Padding
    }
    return list;
  }

  List<ParticleData> get particleObjects => _particleObjects;
}
