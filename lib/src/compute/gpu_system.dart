import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_context.dart';

/// Abstract base class for a System that performs computations on the GPU.
///
/// This class handles the initialization and disposal of the [GpuContext]
/// and provides a simple `compute` method for subclasses to use.
abstract class GpuSystem extends System {
  final GpuContext _gpu = GpuContext();

  /// A flag to ensure initialization happens only once.
  bool _isGpuInitialized = false;

  /// Subclasses must implement this method to provide the initial data
  /// that will be sent to the GPU and reside there.
  void initializeGpu();

  /// Executes a single frame of computation on the GPU.
  ///
  /// [deltaTime] is the time elapsed since the last frame.
  /// Returns the duration of the GPU computation in microseconds.
  int compute(double deltaTime) {
    if (!_isGpuInitialized) {
      // This is a safeguard, initializeGpu() should be called in onAddedToWorld.
      initializeGpu();
    }
    return _gpu.runSimulation(deltaTime);
  }

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Ensure GPU is initialized when the system is added to the world.
    if (!_isGpuInitialized) {
      initializeGpu();
    }
  }

  @override
  void onRemovedFromWorld() {
    // Clean up GPU resources when the system is removed.
    _gpu.dispose();
    _isGpuInitialized = false;
    super.onRemovedFromWorld();
  }
}
