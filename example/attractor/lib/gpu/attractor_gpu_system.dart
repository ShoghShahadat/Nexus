import 'dart:math';
import 'dart:typed_data';

import 'package:nexus/nexus.dart';
import '../events.dart';

part 'attractor_gpu_system.g.dart';

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

@transpileGpuSystem
class AttractorGpuSystem extends GpuSystem<ParticleData> {
  final int particleCount;
  final Random _random = Random();
  late List<ParticleData> _particleObjects;

  AttractorGpuSystem({this.particleCount = 500});

  // --- CORRECT IMPLEMENTATION: Gets the shader from the generated part file ---
  @override
  String get wgslSourceCode => _$AttractorGpuSystemWgslSourceCode();

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

  // --- This is the pure Dart logic that will be transpiled to WGSL ---
  @override
  void gpuLogic(ParticleData p, GpuKernelContext ctx) {
    if (p.age >= p.maxAge) {
      p.position.x = ctx.attractorX;
      p.position.y = ctx.attractorY;

      // Note: This logic is slightly different from the hardcoded shader to
      // demonstrate the transpiler's capabilities.
      final angle = (p.initialSize * 1000.0) * 2.0 * 3.14159;
      final speed = 50.0 + (p.initialSize * 50.0);
      p.velocity.x = cos(angle) * speed;
      p.velocity.y = sin(angle) * speed;
      p.age = 0.0;
    }

    final dirX = ctx.attractorX - p.position.x;
    final dirY = ctx.attractorY - p.position.y;
    final distSq = (dirX * dirX) + (dirY * dirY);

    if (distSq > 1.0) {
      final dist = sqrt(distSq);
      final force = ctx.attractorStrength * 1000.0 / distSq;
      p.velocity.x = p.velocity.x + (dirX / dist) * force * ctx.deltaTime;
      p.velocity.y = p.velocity.y + (dirY / dist) * force * ctx.deltaTime;
    }

    p.position.x = p.position.x + p.velocity.x * ctx.deltaTime;
    p.position.y = p.position.y + p.velocity.y * ctx.deltaTime;
    p.age = p.age + ctx.deltaTime;
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
      list[baseIndex + 7] = 0.0; // Padding
    }
    return list;
  }

  List<ParticleData> get particleObjects => _particleObjects;
}
