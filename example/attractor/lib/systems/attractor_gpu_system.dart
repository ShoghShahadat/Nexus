import 'dart:async';
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

// 1. Define the data structure for a single particle.
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
  // This list is now correctly managed by the base class's _cpuData.
  // We keep a reference for easy access.
  late List<ParticleData> _particleObjects;

  AttractorGpuSystem({this.particleCount = 500});

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ResetSimulationEvent>((_) => _resetSimulation());
  }

  void _resetSimulation() {
    // --- CRITICAL FIX: Call the new base class method ---
    // This ensures the correct data list (_cpuData) is updated.
    reinitializeData();
  }

  @override
  List<ParticleData> initializeData() {
    // This method now correctly populates the base class's _cpuData list.
    _particleObjects = List.generate(particleCount, (i) {
      final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
      final w = screenInfo?.width ?? 400;
      final h = screenInfo?.height ?? 800;
      return _createParticle(w / 2, h * 0.8); // Start near the player
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
    final uniforms = world.rootEntity.get<GpuUniformsComponent>()!;
    final dx = uniforms.attractorX - p.position.x;
    final dy = uniforms.attractorY - p.position.y;
    final distSq = dx * dx + dy * dy;

    if (distSq > 25) {
      final force = (uniforms.attractorStrength * 45000) / distSq;
      final angle = atan2(dy, dx);
      p.velocity.x += cos(angle) * force * ctx.deltaTime;
      p.velocity.y += sin(angle) * force * ctx.deltaTime;
    }
    p.position.x += p.velocity.x * ctx.deltaTime;
    p.position.y += p.velocity.y * ctx.deltaTime;

    p.age += ctx.deltaTime;
    if (p.age >= p.maxAge) {
      // --- CRITICAL FIX: Reset particles at the attractor's current position ---
      _resetParticle(p, uniforms.attractorX, uniforms.attractorY);
    }
  }

  void _resetParticle(ParticleData p, double x, double y) {
    p.age = 0.0;
    p.position.x = x;
    p.position.y = y;
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 150 + 50;
    p.velocity.x = cos(angle) * speed;
    p.velocity.y = sin(angle) * speed;
  }

  @override
  Float32List flattenData(List<ParticleData> data) {
    if (data.isEmpty) return Float32List(0);
    final list = Float32List(data.length * 7);
    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      final baseIndex = i * 7;
      list[baseIndex + 0] = p.position.x;
      list[baseIndex + 1] = p.position.y;
      list[baseIndex + 2] = p.velocity.x;
      list[baseIndex + 3] = p.velocity.y;
      list[baseIndex + 4] = p.age;
      list[baseIndex + 5] = p.maxAge;
      list[baseIndex + 6] = p.initialSize;
    }
    return list;
  }

  List<ParticleData> get particleObjects => _particleObjects;
}
