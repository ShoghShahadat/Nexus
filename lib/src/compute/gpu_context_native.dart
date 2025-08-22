import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:nexus/src/compute/gpu_buffer_native.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

// FFI Signatures for the Rust core library
typedef InitGpuC = Pointer<Void> Function(
    Pointer<Float> initial_data, Int32 len);
typedef InitGpuDart = Pointer<Void> Function(
    Pointer<Float> initial_data, int len);

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

  void initialize(GpuBuffer<Float> buffer) {
    if (_isInitialized) return;
    _loadLibrary();
    _context = _initGpu(buffer.pointer, buffer.length);
    if (_context == nullptr) {
      throw Exception(
          'Failed to initialize GPU context. The native code returned a null pointer.');
    }
    _isInitialized = true;
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
    // 1. Allocate a temporary native buffer
    final buffer = malloc.allocate<Float>(sizeOf<Float>() * length);
    try {
      // 2. Ask Rust to fill our temporary buffer with GPU data
      _readGpuBuffer(_context!, buffer, length);

      // 3. Create a Dart-side view of the native data
      final view = buffer.asTypedList(length);

      // --- CRITICAL FIX: Create a safe copy ---
      // Instead of returning the view (which points to memory we are about to free),
      // we create a new Float32List. This copies the data from the native buffer
      // into a new, garbage-collected Dart object.
      // --- اصلاح حیاتی: ایجاد یک کپی امن ---
      // به جای بازگرداندن نما (که به حافظه‌ای اشاره دارد که می‌خواهیم آزاد کنیم)،
      // یک Float32List جدید ایجاد می‌کنیم. این کار داده‌ها را از بافر نیتیو
      // به یک شیء جدید Dart که توسط garbage collector مدیریت می‌شود، کپی می‌کند.
      final safeList = Float32List.fromList(view);

      // 5. Return the safe, Dart-managed copy
      return safeList;
    } finally {
      // 4. ALWAYS free the temporary native buffer
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
    // This path assumes the DLL is copied to a `rust_lib` directory
    // next to the executable. The build script handles this.
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
