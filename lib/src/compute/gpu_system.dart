import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_context.dart';

enum GpuMode {
  notInitialized,
  gpu,
  cpuFallback,
}

class GpuKernelContext {
  final double deltaTime;
  GpuKernelContext({required this.deltaTime});
}

abstract class GpuSystem<T> extends System {
  final GpuContext _gpu = GpuContext();
  GpuMode _mode = GpuMode.notInitialized;

  GpuMode get mode => _mode;

  late List<T> _cpuData;
  GpuBuffer<dynamic>? _gpuDataBuffer;

  List<T> initializeData();

  @protected
  void gpuLogic(T element, GpuKernelContext ctx);

  void reinitializeData() {
    _cpuData = initializeData();
  }

  Future<int> compute(double deltaTime) async {
    if (_mode == GpuMode.gpu) {
      // --- FIX: No longer need a dynamic cast as the API is now unified ---
      return await _gpu.runSimulation(deltaTime);
    } else if (_mode == GpuMode.cpuFallback) {
      final stopwatch = Stopwatch()..start();
      final ctx = GpuKernelContext(deltaTime: deltaTime);
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
      // The dynamic cast is still needed for initialize because the parameter types differ.
      if (kIsWeb) {
        await (_gpu as dynamic).initialize(flatData);
      } else {
        _gpuDataBuffer = Float32GpuBuffer.fromList(flatData);
        await (_gpu as dynamic).initialize(_gpuDataBuffer!);
      }

      _mode = GpuMode.gpu;
      debugPrint(
          '[Nexus GpuSystem] Successfully initialized in GPU mode. All computations will be offloaded.');
    } catch (e) {
      _mode = GpuMode.cpuFallback;
      debugPrint(
          '[Nexus GpuSystem] WARNING: Failed to initialize GPU context. Reason: $e');
      debugPrint(
          '[Nexus GpuSystem] Switched to CPU Fallback mode. Performance may be degraded.');
    }
  }

  @override
  void onRemovedFromWorld() {
    _gpu.dispose();
    _gpuDataBuffer?.dispose();
    _mode = GpuMode.notInitialized;
    super.onRemovedFromWorld();
  }

  Float32List getGpuDataAsFloat32List() {
    return flattenData(_cpuData);
  }

  Float32List flattenData(List<T> data);

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
