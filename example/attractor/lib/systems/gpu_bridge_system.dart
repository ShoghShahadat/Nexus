import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'attractor_gpu_system.dart';
import '../components/debug_info_component.dart';
import '../components/gpu_particle_render_component.dart';
import 'package:nexus/src/compute/gpu_context.dart';

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
  void update(Entity entity, double dt) async {
    if (_gpuSystem == null) return;

    final blackboard = entity.get<BlackboardComponent>();
    final isGameOver = blackboard?.get<bool>('is_game_over') ?? false;

    final attractor = world.entities.values
        .firstWhereOrNull((e) => e.has<AttractorComponent>());
    final screenInfo = entity.get<ScreenInfoComponent>();

    double attractorX = 0.0, attractorY = 0.0, attractorStrength = 0.0;

    if (attractor != null && screenInfo != null) {
      final attractorPos = attractor.get<PositionComponent>()!;
      final attractorComp = attractor.get<AttractorComponent>()!;
      attractorX = attractorPos.x;
      attractorY = attractorPos.y;
      attractorStrength = attractorComp.strength;
    }

    final int gpuMicros = await _gpuSystem!.compute(
      dt,
      attractorX: attractorX,
      attractorY: attractorY,
      attractorStrength: attractorStrength,
    );
    entity.add(GpuTimeComponent(gpuMicros));

    if (isGameOver) return;

    if (!kIsWeb && _gpuSystem!.mode == GpuMode.gpu) {
      final gpuContext = GpuContext();
      // --- FIX: Stride is now 8 to match the shader ---
      final flatData = (gpuContext as dynamic)
          .readBuffer(_gpuSystem!.particleObjects.length * 8);

      for (int i = 0; i < _gpuSystem!.particleObjects.length; i++) {
        final p = _gpuSystem!.particleObjects[i];
        final baseIndex = i * 8;
        p.position.x = flatData[baseIndex + 0];
        p.position.y = flatData[baseIndex + 1];
        p.velocity.x = flatData[baseIndex + 2];
        p.velocity.y = flatData[baseIndex + 3];
        p.age = flatData[baseIndex + 4];
        // maxAge and initialSize are read-only and don't need to be updated from GPU
      }
    }

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

        final newAlpha = (255 * (1.0 - progress)).round();
        final colorValue =
            Colors.redAccent.withAlpha(newAlpha).value.toDouble();

        renderData[destIndex + 3] = -colorValue;
        if (_explosionStates[i] >= 1.0) {
          _explosionStates[i] = 0.0;
        }
      }
    }
    entity.add(GpuParticleRenderComponent(renderData));
  }
}
