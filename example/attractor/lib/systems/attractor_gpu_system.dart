import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart'; // Import for Color
import 'package:nexus/nexus.dart';

// A simple 2D vector class for our particle data structure.
class Vec2 with EquatableMixin {
  double x, y;
  Vec2(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

// 1. Define the data structure for a single particle.
// This is now a plain Dart object, not a Component, as it's managed
// internally by the GpuSystem.
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

// 2. Create the GpuSystem by extending the base class.
// The generic type is the Dart object we want to simulate.
class AttractorGpuSystem extends GpuSystem<ParticleData> {
  final int particleCount;
  final Random _random = Random();

  // This is now private and managed by the base GpuSystem.
  // We can access it via a getter if needed.
  late final List<ParticleData> _particleObjects;

  AttractorGpuSystem({this.particleCount = 500});

  // This method is called by the base class during initialization.
  @override
  List<ParticleData> initializeData() {
    _particleObjects = List.generate(particleCount, (i) {
      return _createParticle(200, 400);
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
      maxAge: _random.nextDouble() * 3 + 2, // Random lifespan
      initialSize: _random.nextDouble() * 2.0 + 1.0,
    );
  }

  // 3. Write the logic for a SINGLE particle in Dart.
  // This code will be executed on the CPU if the GPU is not available.
  @override
  void gpuLogic(ParticleData p, GpuKernelContext ctx) {
    final uniforms = world.rootEntity.get<GpuUniformsComponent>()!;

    // --- Attraction & Physics ---
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

    // --- Lifecycle & Recycling ---
    p.age += ctx.deltaTime;
    if (p.age >= p.maxAge) {
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

  // This method is no longer needed here, as the base class handles it.
  // We keep it for reference or potential custom CPU logic.
  void simulateCpuExecution(double dt) {
    final ctx = GpuKernelContext(deltaTime: dt);
    for (final p in _particleObjects) {
      gpuLogic(p, ctx);
    }
  }

  // This method is required by the base class to structure the data for the GPU.
  @override
  Float32List flattenComponentData(List<ParticleData> components) {
    if (components.isEmpty) return Float32List(0);
    // Stride is now 7 (px, py, vx, vy, age, maxAge, initialSize)
    final list = Float32List(components.length * 7);
    for (int i = 0; i < components.length; i++) {
      final p = components[i];
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

  // A public getter to allow other systems to access the particle data for rendering.
  List<ParticleData> get particleObjects => _particleObjects;
}
