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
/// This new version dynamically transpiles Dart-like shader code into WGSL.
abstract class GpuSystem<T> extends System {
  final GpuContext _gpu = GpuContext();
  GpuMode _mode = GpuMode.notInitialized;

  GpuMode get mode => _mode;

  late List<T> _cpuData;
  GpuBuffer<dynamic>? _gpuDataBuffer;

  /// The source code for the GPU logic, written in a subset of Dart.
  String get gpuLogicSourceCode;

  /// Initializes the particle data on the CPU.
  List<T> initializeData();

  /// Flattens the structured Dart data into a raw list of floats for the GPU.
  Float32List flattenData(List<T> data);

  /// Re-initializes data, for events like "Restart Game".
  void reinitializeData() {
    _cpuData = initializeData();
  }

  /// Executes the computation.
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
    } else if (_mode == GpuMode.cpuFallback) {
      // CPU fallback is no longer the main focus, as transpilation should work.
      // This can be expanded later if needed.
      return 0;
    }
    return 0;
  }

  /// A very simple transpiler to convert the Dart-like logic to WGSL.
  /// NOTE: This is a proof-of-concept and only supports basic assignments and arithmetic.
  String _transpileToWgsl() {
    // 1. Define the WGSL struct based on the flattened data layout (8 floats)
    final struct = '''
      struct Particle {
          pos: vec2<f32>,
          vel: vec2<f32>,
          age: f32,
          max_age: f32,
          initial_size: f32,
          seed: f32,
      };
    ''';

    // 2. Define the uniform parameters struct
    final params = '''
      struct SimParams {
          delta_time: f32,
          attractor_x: f32,
          attractor_y: f32,
          attractor_strength: f32,
      };
    ''';

    // 3. Define bindings and helper functions
    final header = '''
      @group(0) @binding(1)
      var<uniform> params: SimParams;

      @group(0) @binding(0)
      var<storage, read_write> particles: array<Particle>;

      fn hash(n: f32) -> f32 {
          return fract(sin(n) * 43758.5453123);
      }
    ''';

    // 4. Clean up and adapt the user's Dart code
    String userLogic = gpuLogicSourceCode
        .replaceAll('void gpuLogic(Particle p, SimParams params) {', '')
        .replaceAll(RegExp(r'}\s*$'), ''); // Remove start and end of function
    userLogic = userLogic.replaceAll(
        'let ', 'var '); // WGSL uses 'var' for mutable variables

    // 5. Assemble the final shader code
    final mainFunction = '''
      @compute @workgroup_size(256)
      fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
          let index = global_id.x;
          let array_len = arrayLength(&particles);
          if (index >= array_len) {
              return;
          }
          var p = particles[index];

          ${userLogic}

          particles[index] = p;
      }
    ''';

    return '$struct\n$params\n$header\n$mainFunction';
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
      final shaderCode = _transpileToWgsl();
      debugPrint("--- Transpiled WGSL Shader ---\n$shaderCode");

      if (kIsWeb) {
        // Web implementation would also pass the shaderCode
        await (_gpu as dynamic).initialize(flatData, shaderCode);
      } else {
        _gpuDataBuffer = Float32GpuBuffer.fromList(flatData);
        // Pass the dynamically generated shader to the native side
        await (_gpu as dynamic).initialize(_gpuDataBuffer!, shaderCode);
      }

      _mode = GpuMode.gpu;
      debugPrint(
          '[Nexus GpuSystem] Successfully initialized in GPU mode (Dynamic Shader).');
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
