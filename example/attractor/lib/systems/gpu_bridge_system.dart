import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'attractor_gpu_system.dart';
import '../components/gpu_particle_render_component.dart';

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

  // update is now async to accommodate the async compute method.
  @override
  void update(Entity entity, double dt) async {
    if (_gpuSystem == null) return;

    final blackboard = entity.get<BlackboardComponent>();
    final isGameOver = blackboard?.get<bool>('is_game_over') ?? false;

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

    if (isGameOver) {
      return;
    }

    // Await the compute result.
    await _gpuSystem!.compute(dt);

    // The rest of the logic remains the same, as it reads from the CPU-side data.
    final particleObjects = _gpuSystem!.particleObjects;
    final renderData = Float32List(particleObjects.length * 4);

    for (int i = 0; i < particleObjects.length; i++) {
      final p = particleObjects[i];
      final destIndex = i * 4;

      renderData[destIndex + 0] = p.position.x;
      renderData[destIndex + 1] = p.position.y;

      if (_explosionStates[i] == 0.0) {
        final progress = (p.age / p.maxAge).clamp(0.0, 1.0);
        renderData[destIndex + 2] = p.initialSize * (1.0 - progress);
        final opacity = 1.0 - progress;
        renderData[destIndex + 3] = opacity.clamp(0.0, 1.0);
        if (_random.nextDouble() < 0.0005) {
          _explosionStates[i] = 0.001;
        }
      } else {
        _explosionStates[i] += dt / 0.7;
        final progress = _explosionStates[i].clamp(0.0, 1.0);
        renderData[destIndex + 2] = p.initialSize + (progress * 15);
        final colorValue =
            Colors.redAccent.withOpacity(1.0 - progress).value.toDouble();
        renderData[destIndex + 3] = -colorValue;
        if (_explosionStates[i] >= 1.0) {
          _explosionStates[i] = 0.0;
        }
      }
    }
    entity.add(GpuParticleRenderComponent(renderData));
  }
}
