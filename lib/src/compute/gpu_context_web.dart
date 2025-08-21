import 'ffi_web_stub.dart';
import 'gpu_buffer_web.dart';

// This file provides a web-safe "stub" implementation of the GpuContext.
// It now accepts a GpuBuffer to match the native API, but still throws.

class GpuContext {
  static final GpuContext _instance = GpuContext._internal();
  factory GpuContext() => _instance;
  GpuContext._internal();

  /// On the web, FFI is not supported, so we immediately fail initialization.
  /// The GpuSystem will catch this exception and switch to CPU fallback mode.
  void initialize(GpuBuffer<Float> buffer) {
    throw UnsupportedError(
        'GPU context cannot be initialized on the web platform.');
  }

  int runSimulation(double deltaTime) {
    throw StateError('GpuContext is not available on the web.');
  }

  void dispose() {}
}
