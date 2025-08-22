import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:nexus/src/compute/gpu_buffer_native.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

// --- MODIFIED FFI Signature: Added shader_source parameter ---
typedef InitGpuC = Pointer<Void> Function(
    Pointer<Float> initial_data, Int32 len, Pointer<Utf8> shader_source);
typedef InitGpuDart = Pointer<Void> Function(
    Pointer<Float> initial_data, int len, Pointer<Utf8> shader_source);

typedef ReleaseGpuC = Void Function(Pointer<Void> context);
typedef ReleaseGpuDart = void Function(Pointer<Void> context);

typedef GpuSimC = Uint64 Function(Pointer<Void> context, Float delta_time,
    Float attractor_x, Float attractor_y, Float attractor_strength);
typedef GpuSimDart = int Function(Pointer<Void> context, double delta_time,
    double attractor_x, double attractor_y, double attractor_strength);

typedef ReadGpuC = Void Function(
    Pointer<Void> context, Pointer<Float> output, Int32 len);
typedef ReadGpuDart = void Function(
    Pointer<Void> context, Pointer<Float> output, int len);

class GpuContext {
  static final GpuContext _instance = GpuContext._internal();
  factory GpuContext() => _instance;

  late final DynamicLibrary _lib;
  late final InitGpuDart _initGpu;
  late final ReleaseGpuDart _releaseGpu;
  late final GpuSimDart _runGpuSimulation;
  late final ReadGpuDart _readGpuBuffer;

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
      _readGpuBuffer =
          _lib.lookup<NativeFunction<ReadGpuC>>('read_gpu_buffer').asFunction();
    } catch (e) {
      throw Exception('Failed to load GPU native library or functions: $e');
    }
  }

  // --- MODIFIED: Accepts shaderSource string ---
  void initialize(GpuBuffer<Float> buffer, String shaderSource) {
    if (_isInitialized) return;
    _loadLibrary();
    final shaderSourcePtr = shaderSource.toNativeUtf8();
    try {
      _context = _initGpu(buffer.pointer, buffer.length, shaderSourcePtr);
      if (_context == nullptr) {
        throw Exception(
            'Failed to initialize GPU context. The native code returned a null pointer.');
      }
      _isInitialized = true;
    } finally {
      malloc.free(shaderSourcePtr);
    }
  }

  Future<int> runSimulation(double deltaTime, double attractorX,
      double attractorY, double attractorStrength) async {
    if (!_isInitialized || _context == null) {
      throw StateError(
          'GpuContext is not initialized. Call initialize() first.');
    }
    return Future.value(_runGpuSimulation(
        _context!, deltaTime, attractorX, attractorY, attractorStrength));
  }

  Float32List readBuffer(int length) {
    if (!_isInitialized || _context == null) {
      throw StateError('GpuContext is not initialized.');
    }
    final buffer = malloc.allocate<Float>(sizeOf<Float>() * length);
    try {
      _readGpuBuffer(_context!, buffer, length);
      final view = buffer.asTypedList(length);
      final safeList = Float32List.fromList(view);
      return safeList;
    } finally {
      malloc.free(buffer);
    }
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
