import 'dart:ffi';
import 'dart:typed_data'; // --- FIX: Added missing import for Float32List ---
import 'package:nexus/nexus.dart';
import 'package:nexus/src/compute/gpu_buffer.dart';
import 'package:nexus/src/compute/gpu_context.dart';
import 'package:meta/meta.dart';

/// Abstract base class for a System that performs computations on the GPU.
///
/// To use it, extend this class and provide the Component type you want to
/// operate on. Then, implement the `gpuLogic` method with your Dart code
/// that will be transpiled to a GPU shader.
abstract class GpuSystem<T extends Component> extends System {
  final GpuContext _gpu = GpuContext();

  /// The buffer holding the component data on the CPU side.
  late final GpuBuffer<dynamic>
      dataBuffer; // Use dynamic for the generic buffer

  /// A flag to ensure initialization happens only once.
  bool _isGpuInitialized = false;

  /// Subclasses must implement this method to provide the initial list of
  /// components that will be sent to the GPU and reside there.
  List<T> initializeData();

  /// The core of the GpuSystem. Write your per-element logic in this method
  /// using Dart. The framework will transpile this method's body to a
  /// WGSL compute shader and run it on the GPU.
  ///
  /// The parameter [element] is a proxy for one instance of your component
  /// on the GPU. [ctx] provides access to global shader variables.
  @protected
  void gpuLogic(T element, GpuKernelContext ctx);

  /// Executes a single frame of computation on the GPU.
  ///
  /// [deltaTime] is the time elapsed since the last frame.
  /// Returns the duration of the GPU computation in microseconds.
  int compute(double deltaTime) {
    if (!_isGpuInitialized) {
      throw StateError('GpuSystem was not initialized correctly.');
    }
    return _gpu.runSimulation(deltaTime);
  }

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Ensure GPU is initialized when the system is added to the world.
    if (!_isGpuInitialized) {
      final initialComponents = initializeData();

      final flatData = flattenComponentData(initialComponents);
      dataBuffer = Float32GpuBuffer.fromList(flatData);

      // In the future, the transpiler would be invoked here.
      // For now, we call the simplified init function.
      _gpu.initialize(dataBuffer.pointer as Pointer<Float>, dataBuffer.length);

      _isGpuInitialized = true;
    }
  }

  @override
  void onRemovedFromWorld() {
    _gpu.dispose();
    dataBuffer.dispose();
    _isGpuInitialized = false;
    super.onRemovedFromWorld();
  }

  // This is a placeholder for a more sophisticated reflection/serialization system.
  Float32List flattenComponentData(List<T> components);

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {
    // By default, GpuSystem runs its logic via the `compute` method,
    // which is typically called once per frame from a central point.
  }
}

/// A context object providing access to global variables inside `gpuLogic`.
class GpuKernelContext {
  /// The time elapsed since the last frame, in seconds.
  final double deltaTime;

  // FIX: Added a constructor to accept deltaTime.
  GpuKernelContext({required this.deltaTime});
}
