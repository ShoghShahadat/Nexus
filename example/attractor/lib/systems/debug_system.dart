import 'dart:collection';
import 'package:attractor_example/gpu/attractor_gpu_system.dart';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/debug_info_component.dart';

/// A system that calculates and provides real-time performance metrics.
class DebugSystem extends System {
  final Queue<double> _frameTimes = Queue<double>();
  final int _sampleSize = 60; // Average over 60 frames

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // We use the delta time (dt) provided by the engine for frame time calculation.
    _frameTimes.addLast(dt);
    if (_frameTimes.length > _sampleSize) {
      _frameTimes.removeFirst();
    }

    final totalFrameTime = _frameTimes.fold<double>(0, (prev, t) => prev + t);
    final averageFrameTime = totalFrameTime / _frameTimes.length;

    // --- FIX: More accurate FPS calculation ---
    // FPS is the reciprocal of the average frame time in seconds.
    // If averageFrameTime is 0, FPS is effectively infinite, but we cap it for display.
    final double fps = (averageFrameTime > 0) ? 1.0 / averageFrameTime : 0.0;

    final entityCount = world.entities.length;
    final gpuSystem = world.systems.whereType<AttractorGpuSystem>().firstOrNull;
    final gpuMode = gpuSystem?.mode.toString().split('.').last ?? 'N/A';

    entity.add(DebugInfoComponent(
      // Display the newly calculated, more accurate FPS.
      fps: fps,
      // Display the average frame time in milliseconds.
      frameTime: averageFrameTime * 1000,
      entityCount: entityCount,
      gpuMode: gpuMode.toUpperCase(),
    ));
  }
}
