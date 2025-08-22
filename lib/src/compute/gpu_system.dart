import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_context.dart';

enum GpuMode {
  notInitialized,
  gpu,
  cpuFallback,
}

class GpuKernelContext {
  final double deltaTime;
  final double attractorX;
  final double attractorY;
  final double attractorStrength;

  GpuKernelContext({
    required this.deltaTime,
    this.attractorX = 0.0,
    this.attractorY = 0.0,
    this.attractorStrength = 0.0,
  });
}

// --- FIX: The annotation class is now public ---
/// Annotation to mark a GpuSystem for shader transpilation.
class TranspileGpuSystem {
  const TranspileGpuSystem();
}

/// The constant instance of the annotation to be used on classes.
const transpileGpuSystem = TranspileGpuSystem();

abstract class GpuSystem<T> extends System {
  final GpuContext _gpu = GpuContext();
  GpuMode _mode = GpuMode.notInitialized;

  GpuMode get mode => _mode;

  late List<T> _cpuData;
  GpuBuffer<dynamic>? _gpuDataBuffer;

  @protected
  void gpuLogic(T p, GpuKernelContext ctx);

  String get wgslSourceCode;

  List<T> initializeData();

  void reinitializeData() {
    _cpuData = initializeData();
  }

  Future<int> compute(
    double deltaTime, {
    double attractorX = 0.0,
    double attractorY = 0.0,
    double attractorStrength = 0.0,
  }) async {
    if (_mode == GpuMode.gpu) {
      return await (_gpu as dynamic)
          .runSimulation(deltaTime, attractorX, attractorY, attractorStrength);
    } else if (_mode == GpuMode.cpuFallback) {
      final stopwatch = Stopwatch()..start();
      final ctx = GpuKernelContext(
        deltaTime: deltaTime,
        attractorX: attractorX,
        attractorY: attractorY,
        attractorStrength: attractorStrength,
      );
      for (final element in _cpuData) {
        gpuLogic(element, ctx);
      }
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds;
    }
    return 0;
  }

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    if (_mode == GpuMode.notInitialized) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    _cpuData = initializeData();
    final flatData = flattenData(_cpuData);

    try {
      final shader = wgslSourceCode;
      if (kIsWeb) {
        await (_gpu as dynamic).initialize(flatData, shader);
      } else {
        _gpuDataBuffer = Float32GpuBuffer.fromList(flatData);
        await (_gpu as dynamic).initialize(_gpuDataBuffer!, shader);
      }

      _mode = GpuMode.gpu;
      debugPrint('[Nexus GpuSystem] Successfully initialized in GPU mode.');
    } catch (e) {
      _mode = GpuMode.cpuFallback;
      debugPrint(
          '[Nexus GpuSystem] WARNING: Failed to initialize GPU context. Reason: $e');
      debugPrint('[Nexus GpuSystem] Switched to CPU Fallback mode.');
    }
  }

  @override
  void onRemovedFromWorld() {
    _gpu.dispose();
    _gpuDataBuffer?.dispose();
    _mode = GpuMode.notInitialized;
    super.onRemovedFromWorld();
  }

  Float32List flattenData(List<T> data);

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
