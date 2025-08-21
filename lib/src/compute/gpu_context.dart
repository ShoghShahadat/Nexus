import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// FFI Signatures for the Rust core library
typedef InitGpuC = Pointer<Void> Function(
    Pointer<Float> initial_data, Int32 len);
typedef InitGpuDart = Pointer<Void> Function(
    Pointer<Float> initial_data, int len);

typedef ReleaseGpuC = Void Function(Pointer<Void> context);
typedef ReleaseGpuDart = void Function(Pointer<Void> context);

typedef GpuSimC = Uint64 Function(Pointer<Void> context, Float delta_time);
typedef GpuSimDart = int Function(Pointer<Void> context, double delta_time);

/// A singleton class that manages the low-level communication with the GPU
/// via the Rust FFI bridge. This class is for internal framework use.
class GpuContext {
  static final GpuContext _instance = GpuContext._internal();
  factory GpuContext() => _instance;

  late final DynamicLibrary _lib;
  late final InitGpuDart _initGpu;
  late final ReleaseGpuDart _releaseGpu;
  late final GpuSimDart _runGpuSimulation;

  Pointer<Void>? _context;

  GpuContext._internal() {
    _lib = DynamicLibrary.open(_libPath);
    _initGpu = _lib.lookup<NativeFunction<InitGpuC>>('init_gpu').asFunction();
    _releaseGpu =
        _lib.lookup<NativeFunction<ReleaseGpuC>>('release_gpu').asFunction();
    _runGpuSimulation =
        _lib.lookup<NativeFunction<GpuSimC>>('run_gpu_simulation').asFunction();
  }

  /// Initializes the GPU context with the initial data from a buffer.
  /// This must be called once before any computation.
  void initialize(Pointer<Float> initialData, int length) {
    if (_context == null) {
      _context = _initGpu(initialData, length);
    }
  }

  /// Runs a single frame of the GPU simulation.
  /// Returns the duration of the computation in microseconds.
  int runSimulation(double deltaTime) {
    if (_context == null) {
      throw StateError(
          'GpuContext is not initialized. Call initialize() first.');
    }
    return _runGpuSimulation(_context!, deltaTime);
  }

  /// Releases the GPU resources.
  /// This should be called when the application is closing.
  void dispose() {
    if (_context != null) {
      _releaseGpu(_context!);
      _context = null;
    }
  }

  String get _libPath {
    // This path logic needs to be robust for different platforms.
    if (Platform.isWindows) {
      return path.join(Directory.current.path, 'rust_lib', 'rust_core.dll');
    }
    // Add paths for other platforms (Android, Linux, macOS) here.
    throw Exception('Unsupported platform for GpuContext');
  }
}
