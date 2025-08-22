import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:nexus/src/compute/gpu_buffer_native.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

// --- CRITICAL FIX: Update FFI signatures to accept the shader code string ---
// The native function now expects a pointer to the initial data, its length,
// and a pointer to the UTF8-encoded shader code string.
// --- اصلاح حیاتی: به‌روزرسانی امضای FFI برای پذیرش رشته کد شیدر ---
// تابع نیتیو اکنون یک اشاره‌گر به داده‌های اولیه، طول آن، و یک اشاره‌گر
// به رشته کد شیدر با انکدینگ UTF8 را انتظار دارد.
typedef InitGpuC = Pointer<Void> Function(
    Pointer<Float> initial_data, Int32 len, Pointer<Utf8> shader_code);
typedef InitGpuDart = Pointer<Void> Function(
    Pointer<Float> initial_data, int len, Pointer<Utf8> shader_code);

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

  // --- CRITICAL FIX: Update the method signature to accept the shader code ---
  // --- اصلاح حیاتی: به‌روزرسانی امضای متد برای پذیرش کد شیدر ---
  void initialize(GpuBuffer<Float> buffer, String shaderCode) {
    if (_isInitialized) return;
    _loadLibrary();

    // Convert the Dart String to a C-compatible, null-terminated UTF8 string.
    // رشته Dart را به یک رشته UTF8 سازگار با C تبدیل می‌کنیم.
    final shaderCodeC = shaderCode.toNativeUtf8();

    try {
      _context = _initGpu(buffer.pointer, buffer.length, shaderCodeC);
      if (_context == nullptr) {
        throw Exception(
            'Failed to initialize GPU context. The native code returned a null pointer.');
      }
      _isInitialized = true;
    } finally {
      // ALWAYS free the allocated native string memory to prevent memory leaks.
      // همیشه حافظه اختصاص داده شده به رشته نیتیو را برای جلوگیری از نشت حافظه آزاد می‌کنیم.
      malloc.free(shaderCodeC);
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
