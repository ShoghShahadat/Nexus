import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_context.dart';

enum GpuMode {
  notInitialized,
  gpu,
  cpuFallback,
}

/// A base class for systems that perform high-performance computations on the GPU.
/// This version expects a pre-transpiled WGSL shader code, provided by a generated
/// part file via the `wgslSourceCode` getter.
abstract class GpuSystem<T> extends System {
  final GpuContext _gpu = GpuContext();
  GpuMode _mode = GpuMode.notInitialized;

  GpuMode get mode => _mode;

  late List<T> _cpuData;
  GpuBuffer<dynamic>? _gpuDataBuffer;

  /// Subclasses must implement this getter to provide the WGSL source code.
  /// This will typically be a constant from a generated `.g.dart` file.
  /// کلاس‌های فرزند باید این getter را برای ارائه سورس کد WGSL پیاده‌سازی کنند.
  /// این معمولاً یک ثابت از یک فایل تولید شده `.g.dart` خواهد بود.
  String get wgslSourceCode;

  List<T> initializeData();
  Float32List flattenData(List<T> data);

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
      return await (_gpu as dynamic).runSimulation(
        deltaTime,
        attractorX,
        attractorY,
        attractorStrength,
      );
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
      final shaderCode = wgslSourceCode;
      if (shaderCode.isEmpty) {
        throw Exception(
            "wgslSourceCode getter returned an empty string. Did the build_runner run?");
      }

      if (kIsWeb) {
        await (_gpu as dynamic).initialize(flatData, shaderCode);
      } else {
        _gpuDataBuffer = Float32GpuBuffer.fromList(flatData);
        await (_gpu as dynamic).initialize(_gpuDataBuffer!, shaderCode);
      }

      _mode = GpuMode.gpu;
      debugPrint(
          '[Nexus GpuSystem] Successfully initialized in GPU mode (Build-Time Transpiled).');
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

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
