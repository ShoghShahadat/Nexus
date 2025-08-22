import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:nexus/src/compute/gpu_buffer_native.dart';
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
  bool _isInitialized = false;

  GpuContext._internal();

  void _loadLibrary() {
    final libPath = _getLibraryPath();
    if (libPath == null) {
      throw Exception('GPU native library not found for this platform.');
    }
    try {
      _lib = DynamicLibrary.open(libPath);
      _initGpu = _lib.lookup<NativeFunction<InitGpuC>>('init_gpu').asFunction();
      _releaseGpu =
          _lib.lookup<NativeFunction<ReleaseGpuC>>('release_gpu').asFunction();
      _runGpuSimulation = _lib
          .lookup<NativeFunction<GpuSimC>>('run_gpu_simulation')
          .asFunction();
    } catch (e) {
      throw Exception('Failed to load GPU native library or functions: $e');
    }
  }

  void initialize(GpuBuffer<Float> buffer) {
    if (_isInitialized) return;

    _loadLibrary();

    _context = _initGpu(buffer.pointer, buffer.length);

    if (_context == nullptr) {
      throw Exception(
          'Failed to initialize GPU context. The native code returned a null pointer. This might happen if a compatible GPU is not available.');
    }
    _isInitialized = true;
  }

  // --- FIX: Unify the method signature with the web version to be async ---
  Future<int> runSimulation(double deltaTime) async {
    if (!_isInitialized || _context == null) {
      throw StateError(
          'GpuContext is not initialized. Call initialize() first.');
    }
    // The FFI call itself is synchronous/blocking, so we wrap the result in a Future.
    return Future.value(_runGpuSimulation(_context!, deltaTime));
  }

  void dispose() {
    if (_context != null) {
      _releaseGpu(_context!);
      _context = null;
    }
    _isInitialized = false;
  }

  String? _getLibraryPath() {
    if (Platform.isWindows) {
      return path.join(Directory.current.path, 'rust_lib', 'rust_core.dll');
    }
    if (Platform.isLinux || Platform.isAndroid) {
      return path.join(Directory.current.path, 'rust_lib', 'librust_core.so');
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return path.join(
          Directory.current.path, 'rust_lib', 'librust_core.dylib');
    }
    return null;
  }
}
