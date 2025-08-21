import 'dart:typed_data';
import 'ffi_web_stub.dart';

// This file provides a web-safe "stub" implementation of the GpuBuffer classes.
// It now imports the shared web stubs to avoid name conflicts.

abstract class GpuBuffer<T extends NativeType> {
  Pointer<T> get pointer;
  int get length;
  int get elementSizeBytes;
  int get totalSizeBytes => length * elementSizeBytes;
  void dispose();
}

class Float32GpuBuffer extends GpuBuffer<Float> {
  final Float32List _data;

  @override
  Pointer<Float> get pointer =>
      throw UnimplementedError('Pointers are not supported on the web.');

  @override
  int get length => _data.length;

  @override
  int get elementSizeBytes => 4; // 32-bit float is 4 bytes

  factory Float32GpuBuffer.fromList(Float32List list) {
    return Float32GpuBuffer._internal(list);
  }

  Float32GpuBuffer._internal(this._data);

  @override
  void dispose() {
    // No-op on the web, as memory is managed by the Dart VM's garbage collector.
  }

  Float32List toList() {
    return _data;
  }
}
