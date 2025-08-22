import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

// This file provides the web-specific implementation of GpuContext.
// It uses JS interop to load and communicate with the compiled WASM module.

// --- JS Interop Bindings for our WASM module ---

@JS()
@staticInterop
class WasmModule {}

extension WasmModuleExtension on WasmModule {
  @JS('default')
  external JSFunction get defaultInitializer;

  external JSPromise<JSObject> init(JSFloat32Array initialData);
}

@JS('WasmGpuContext')
@staticInterop
class WasmGpuContext {}

extension WasmGpuContextExtension on WasmGpuContext {
  @JS('runSimulation')
  external JSPromise<JSNumber> runSimulation(JSNumber deltaTime);
}

// --- Main GpuContext Implementation for Web ---

class GpuContext {
  static final GpuContext _instance = GpuContext._internal();
  factory GpuContext() => _instance;
  GpuContext._internal();

  WasmGpuContext? _wasmContext;
  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> _initializeWasm(Float32List initialData) async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // --- FIX: Modernized WASM initialization ---
      // Step 1: Load the JavaScript module object.
      final module = await importModule('/assets/pkg/rust_core.js'.toJS).toDart;

      // Step 2: Cast the loaded module and call the default initializer.
      // Modern wasm-bindgen often doesn't require passing the binary manually.
      // The JS glue code handles fetching the .wasm file itself.
      final wasmModule = module as WasmModule;
      final JSPromise initPromise =
          wasmModule.defaultInitializer.callAsFunction(null) as JSPromise;
      await initPromise.toDart;

      // Step 3: Now that the module is fully initialized, call our named 'init' function from lib.rs.
      final jsContext = await wasmModule.init(initialData.toJS).toDart;
      _wasmContext = jsContext as WasmGpuContext;
      _isInitialized = true;
    } catch (e) {
      final errorMessage =
          'Failed to initialize WASM GPU context: ${e.toString()}';
      web.console.error(errorMessage.toJS as JSAny);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> initialize(Float32List initialData) async {
    await _initializeWasm(initialData);
  }

  Future<int> runSimulation(double deltaTime) async {
    if (!_isInitialized || _wasmContext == null) {
      throw StateError('WASM GpuContext is not initialized.');
    }
    final result = await _wasmContext!.runSimulation(deltaTime.toJS).toDart;
    return result.toDartInt;
  }

  void dispose() {
    _wasmContext = null;
    _isInitialized = false;
  }
}
