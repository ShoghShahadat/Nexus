import 'dart:math';
import 'package:attractor_example/gpu/attractor_gpu_system.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
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

    double attractorX = 0.0, attractorY = 0.0, attractorStrength = 0.0;

    if (attractor != null) {
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

    if (isGameOver) {
      entity.add(GpuParticleRenderComponent(Float32List(0)));
      return;
    }

    final flatData =
        (GpuContext() as dynamic).readBuffer(_gpuSystem!.particleCount * 8);

    // --- CRITICAL FIX: Create a NEW list for render data every frame ---
    // This ensures that the EquatableMixin in GpuParticleRenderComponent detects
    // a change and notifies the rendering system to repaint. Mutating a list
    // in place will not trigger the update.
    // --- اصلاح حیاتی: هر فریم یک لیست جدید برای داده‌های رندر ایجاد کنید ---
    // این تضمین می‌کند که EquatableMixin در GpuParticleRenderComponent تغییر را
    // تشخیص داده و به سیستم رندرینگ برای بازрисовانی اطلاع دهد.
    final renderData = Float32List(_gpuSystem!.particleCount * 4);

    for (int i = 0; i < _gpuSystem!.particleCount; i++) {
      final srcIndex = i * 8;
      final destIndex = i * 4;

      final x = flatData[srcIndex + 0];
      final y = flatData[srcIndex + 1];
      final age = flatData[srcIndex + 4];
      final maxAge = flatData[srcIndex + 5];
      final initialSize = flatData[srcIndex + 6];

      renderData[destIndex + 0] = x;
      renderData[destIndex + 1] = y;

      if (_explosionStates[i] == 0.0) {
        final progress = (age / maxAge).clamp(0.0, 1.0);
        renderData[destIndex + 2] = initialSize * (1.0 - progress);
        final opacity = 1.0 - progress;
        renderData[destIndex + 3] = opacity.clamp(0.0, 1.0);

        if (_random.nextDouble() < 0.0005) {
          _explosionStates[i] = 0.001;
        }
      } else {
        _explosionStates[i] += dt / 0.7;
        final progress = _explosionStates[i].clamp(0.0, 1.0);
        renderData[destIndex + 2] = initialSize + (progress * 15);

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
