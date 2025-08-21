import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_context.dart';

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
///
/// To use it, extend this class, provide the Component type `T` you want to
/// operate on, and implement the `gpuLogic` method with your Dart code.
/// The framework will attempt to run this on the GPU, and if it fails, it will

/// automatically run the same Dart code on the CPU.
abstract class GpuSystem<T extends Component> extends System {
  final GpuContext _gpu = GpuContext();
  GpuMode _mode = GpuMode.notInitialized;

  /// The current execution mode of the system (GPU or CPU).
  GpuMode get mode => _mode;

  /// The buffer holding the component data on the CPU side.
  /// This is used for initialization and as the source of truth for CPU fallback.
  late final List<T> _cpuData;

  /// The raw GPU buffer for communication with the native code.
  late final GpuBuffer<dynamic> _gpuDataBuffer;

  /// Subclasses must implement this method to provide the initial list of
  /// components that will be sent to the GPU and reside there.
  List<T> initializeData();

  /// The core of the GpuSystem. Write your per-element logic in this method
  /// using Dart.
  ///
  /// The parameter [element] is one instance of your component.
  /// [ctx] provides access to global shader variables like deltaTime.
  @protected
  void gpuLogic(T element, GpuKernelContext ctx);

  /// Executes a single frame of computation.
  ///
  /// This method intelligently delegates the work to either the GPU or the CPU
  /// based on the initialization outcome.
  /// Returns the duration of the computation in microseconds.
  int compute(double deltaTime) {
    if (_mode == GpuMode.gpu) {
      return _gpu.runSimulation(deltaTime);
    } else if (_mode == GpuMode.cpuFallback) {
      final stopwatch = Stopwatch()..start();
      final ctx = GpuKernelContext(deltaTime: deltaTime);
      for (final component in _cpuData) {
        gpuLogic(component, ctx);
      }
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds;
    }
    return 0; // Not initialized
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
    final flatData = flattenComponentData(_cpuData);

    try {
      _gpuDataBuffer = Float32GpuBuffer.fromList(flatData);
      _gpu.initialize(
          _gpuDataBuffer.pointer as Pointer<Float>, _gpuDataBuffer.length);
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

  /// A utility method to read the data back from the GPU buffer into a Dart list.
  /// In CPU fallback mode, it returns the current state of the CPU data.
  /// Useful for rendering and debugging.
  Float32List getGpuDataAsFloat32List() {
    if (_mode == GpuMode.gpu) {
      // In a real scenario, you'd need an FFI call to read data back from the GPU.
      // For now, we assume the initial buffer is what we want to read.
      // This part needs a proper implementation with a staging buffer in Rust.
      return (_gpuDataBuffer as Float32GpuBuffer).toList();
    } else if (_mode == GpuMode.cpuFallback) {
      // In CPU mode, we just re-flatten the current state of our objects.
      return flattenComponentData(_cpuData);
    }
    return Float32List(0);
  }

  /// Subclasses must implement this to convert their list of components
  /// into a flat list of floats for the GPU.
  Float32List flattenComponentData(List<T> components);

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {
    // By default, GpuSystem runs its logic via the `compute` method,
    // which is typically called once per frame from a central point.
  }
}
