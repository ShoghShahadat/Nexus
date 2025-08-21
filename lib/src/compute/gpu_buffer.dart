import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Abstract base class for a buffer of data that can be sent to the GPU.
abstract class GpuBuffer {
  /// A pointer to the underlying memory of the buffer.
  Pointer<NativeType> get pointer;

  /// The total number of elements in the buffer.
  int get length;

  /// The size of a single element in bytes.
  int get elementSizeBytes;

  /// The total size of the buffer in bytes.
  int get totalSizeBytes => length * elementSizeBytes;

  /// Disposes of the memory allocated by this buffer.
  void dispose();
}

/// A concrete implementation of [GpuBuffer] for a list of 32-bit floats.
/// This class encapsulates the complexity of memory management with FFI.
class Float32GpuBuffer extends GpuBuffer {
  final Pointer<Float> _pointer;
  final int _length;

  @override
  Pointer<Float> get pointer => _pointer;

  @override
  int get length => _length;

  @override
  int get elementSizeBytes => sizeOf<Float>();

  /// Creates a [Float32GpuBuffer] from a [Float32List].
  /// The list data is copied into a newly allocated block of memory.
  factory Float32GpuBuffer.fromList(Float32List list) {
    final ptr = malloc.allocate<Float>(sizeOf<Float>() * list.length);
    final ptrList = ptr.asTypedList(list.length);
    ptrList.setAll(0, list);
    return Float32GpuBuffer._internal(ptr, list.length);
  }

  Float32GpuBuffer._internal(this._pointer, this._length);

  @override
  void dispose() {
    malloc.free(_pointer);
  }

  /// A utility method to read the data back from the GPU buffer into a Dart list.
  /// Useful for debugging.
  Float32List toList() {
    return _pointer.asTypedList(_length);
  }
}
