import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'attractor_gpu_system.dart';
import '../components/gpu_particle_render_component.dart';

/// A system that acts as a bridge between the CPU world and the GPU simulation.
/// It now also controls the visual state (like explosions) of particles.
class GpuBridgeSystem extends System {
  AttractorGpuSystem? _gpuSystem;
  final Random _random = Random();

  List<double> _explosionStates = [];

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _gpuSystem = world.systems.whereType<AttractorGpuSystem>().firstOrNull;
    if (_gpuSystem != null) {
      _explosionStates =
          List.filled(_gpuSystem!.particleCount, 0.0, growable: false);
    }
  }

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    if (_gpuSystem == null) return;

    // --- CRITICAL FIX: Pause simulation on Game Over ---
    // Read the game over state from the blackboard.
    final blackboard = entity.get<BlackboardComponent>();
    final isGameOver = blackboard?.get<bool>('is_game_over') ?? false;

    // 1. Update Uniforms (CPU -> GPU/CPU-Sim)
    // Always update uniforms so the simulation knows the attractor's position on restart.
    final attractor = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());
    final screenInfo = entity.get<ScreenInfoComponent>();

    if (attractor != null && screenInfo != null) {
      final attractorPos = attractor.get<PositionComponent>()!;
      final attractorComp = attractor.get<AttractorComponent>()!;
      entity.add(GpuUniformsComponent(
        attractorX: attractorPos.x,
        attractorY: attractorPos.y,
        attractorStrength: attractorComp.strength,
        screenWidth: screenInfo.width,
        screenHeight: screenInfo.height,
      ));
    }

    // If the game is over, do not run the simulation or update particle visuals.
    // This effectively freezes the particle system.
    if (isGameOver) {
      return;
    }

    // 2. Run GPU/CPU Simulation for physics.
    _gpuSystem!.compute(dt);

    // 3. Retrieve physics data and apply visual logic on CPU.
    final particleObjects = _gpuSystem!.particleObjects;
    final renderData = Float32List(particleObjects.length * 4);

    for (int i = 0; i < particleObjects.length; i++) {
      final p = particleObjects[i];
      final destIndex = i * 4;

      renderData[destIndex + 0] = p.position.x;
      renderData[destIndex + 1] = p.position.y;

      // --- CPU-Side Visual Logic ---
      if (_explosionStates[i] == 0.0) {
        // --- Normal Particle Rendering ---
        final progress = (p.age / p.maxAge).clamp(0.0, 1.0);
        renderData[destIndex + 2] = p.initialSize * (1.0 - progress);

        final opacity = 1.0 - progress;
        renderData[destIndex + 3] = opacity.clamp(0.0, 1.0);

        if (_random.nextDouble() < 0.0005) {
          _explosionStates[i] = 0.001; // Start explosion
        }
      } else {
        // --- Exploding Particle Rendering ---
        _explosionStates[i] += dt / 0.7; // 0.7 second explosion
        final progress = _explosionStates[i].clamp(0.0, 1.0);
        renderData[destIndex + 2] = p.initialSize + (progress * 15);

        final colorValue =
            Colors.redAccent.withOpacity(1.0 - progress).value.toDouble();
        renderData[destIndex + 3] = -colorValue;

        if (_explosionStates[i] >= 1.0) {
          _explosionStates[i] = 0.0; // Explosion finished, back to normal
        }
      }
    }

    // 4. Update the render component on the root entity.
    entity.add(GpuParticleRenderComponent(renderData));
  }
}
