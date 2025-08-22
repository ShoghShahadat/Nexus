import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/debug_info_component.dart';
import 'attractor_gpu_system.dart';

/// A system that calculates and provides real-time performance metrics.
class DebugSystem extends System {
  final Queue<double> _frameTimes = Queue<double>();
  // --- NEW: A queue to store raw GPU computation times for averaging ---
  final Queue<int> _gpuTimes = Queue<int>();
  final int _sampleSize = 60;

  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // --- VSync-limited frame time calculation (for display) ---
    _frameTimes.addLast(dt);
    if (_frameTimes.length > _sampleSize) {
      _frameTimes.removeFirst();
    }
    final totalFrameTime = _frameTimes.fold<double>(0, (prev, t) => prev + t);
    final averageFrameTimeMs = (totalFrameTime / _frameTimes.length) * 1000;

    // --- Potential FPS calculation (based on raw GPU time) ---
    final gpuTimeComp = entity.get<GpuTimeComponent>();
    if (gpuTimeComp != null && gpuTimeComp.microseconds > 0) {
      _gpuTimes.addLast(gpuTimeComp.microseconds);
      if (_gpuTimes.length > _sampleSize) {
        _gpuTimes.removeFirst();
      }
    }

    double potentialFps = 0;
    if (_gpuTimes.isNotEmpty) {
      final totalGpuTime = _gpuTimes.fold<int>(0, (prev, t) => prev + t);
      final averageGpuTime = totalGpuTime / _gpuTimes.length;
      if (averageGpuTime > 0) {
        potentialFps = 1000000.0 / averageGpuTime;
      }
    }

    final entityCount = world.entities.length;
    final gpuSystem = world.systems.whereType<AttractorGpuSystem>().firstOrNull;
    final gpuMode = gpuSystem?.mode.toString().split('.').last ?? 'N/A';

    entity.add(DebugInfoComponent(
      // Use the calculated potential FPS for display
      fps: potentialFps,
      frameTime: averageFrameTimeMs,
      entityCount: entityCount,
      gpuMode: gpuMode.toUpperCase(),
    ));
  }
}
