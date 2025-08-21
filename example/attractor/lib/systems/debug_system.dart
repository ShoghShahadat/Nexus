import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/debug_info_component.dart';
import 'attractor_gpu_system.dart';

/// A system that calculates and provides real-time performance metrics.
class DebugSystem extends System {
  // Use a deque for efficient adding and removing from both ends.
  final Queue<double> _frameTimes = Queue<double>();
  final int _sampleSize = 60; // Average over the last 60 frames for stability.

  @override
  bool matches(Entity entity) {
    // This system runs once per frame on the root entity.
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // Add the latest frame time (delta time) and maintain the sample size.
    _frameTimes.addLast(dt);
    if (_frameTimes.length > _sampleSize) {
      _frameTimes.removeFirst();
    }

    if (_frameTimes.isEmpty) return;

    // Calculate metrics
    final totalTime = _frameTimes.fold<double>(0, (prev, t) => prev + t);
    final averageFrameTimeMs =
        (totalTime / _frameTimes.length) * 1000; // Convert to milliseconds
    final fps = 1.0 / (totalTime / _frameTimes.length);

    // Get other info
    final entityCount = world.entities.length;
    final gpuSystem = world.systems.whereType<AttractorGpuSystem>().firstOrNull;
    final gpuMode = gpuSystem?.mode.toString().split('.').last ?? 'N/A';

    // Update the component on the root entity
    entity.add(DebugInfoComponent(
      fps: fps,
      frameTime: averageFrameTimeMs,
      entityCount: entityCount,
      gpuMode: gpuMode.toUpperCase(),
    ));
  }
}
