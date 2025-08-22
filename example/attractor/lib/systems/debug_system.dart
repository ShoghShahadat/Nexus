import 'dart:collection';
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
    final averageFrameTime =
        _frameTimes.isNotEmpty ? totalFrameTime / _frameTimes.length : 0;

    final double fps = (averageFrameTime > 0) ? 1.0 / averageFrameTime : 0.0;

    final entityCount = world.entities.length;

    // --- MODIFIED: Removed GPU mode logic ---
    entity.add(DebugInfoComponent(
      fps: fps,
      frameTime: averageFrameTime * 1000,
      entityCount: entityCount,
      gpuMode: 'CPU', // Always CPU now
    ));
  }
}
