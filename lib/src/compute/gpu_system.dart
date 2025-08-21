import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_context.dart';

// Note: No 'dart:ffi' import here. This file is now platform-agnostic.

/// Defines the execution mode for the GpuSystem.
enum GpuMode {
  /// The system has not yet been initialized.
  notInitialized,

  /// The system is running computations on the GPU.
  gpu,

  /// The system failed to initialize the GPU and is using the CPU as a fallback.
  cpuFallback,
}

/// A context object providing access to global variables inside `gpuLogic`.
class GpuKernelContext {
  /// The time elapsed since the last frame, in seconds.
  final double deltaTime;

  GpuKernelContext({required this.deltaTime});
}

/// Abstract base class for a System that performs computations on the GPU
/// with a seamless CPU fallback.
abstract class GpuSystem<T> extends System {
  final GpuContext _gpu = GpuContext();
  GpuMode _mode = GpuMode.notInitialized;

  /// The current execution mode of the system (GPU or CPU).
  GpuMode get mode => _mode;

  late final List<T> _cpuData;
  late final GpuBuffer<dynamic> _gpuDataBuffer;

  List<T> initializeData();

  @protected
  void gpuLogic(T element, GpuKernelContext ctx);

  int compute(double deltaTime) {
    if (_mode == GpuMode.gpu) {
      return _gpu.runSimulation(deltaTime);
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

  void _initialize() {
    _cpuData = initializeData();
    final flatData = flattenData(_cpuData);

    try {
      _gpuDataBuffer = Float32GpuBuffer.fromList(flatData);
      // Pass the entire buffer to the context. The context itself will handle
      // extracting the platform-specific pointer.
      _gpu.initialize(_gpuDataBuffer as Float32GpuBuffer);
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
    if (_mode == GpuMode.gpu) {
      _gpu.dispose();
      _gpuDataBuffer.dispose();
    }
    _mode = GpuMode.notInitialized;
    super.onRemovedFromWorld();
  }

  Float32List getGpuDataAsFloat32List() {
    if (_mode == GpuMode.gpu) {
      return (_gpuDataBuffer as Float32GpuBuffer).toList();
    } else if (_mode == GpuMode.cpuFallback) {
      return flattenData(_cpuData);
    }
    return Float32List(0);
  }

  Float32List flattenData(List<T> data);

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
