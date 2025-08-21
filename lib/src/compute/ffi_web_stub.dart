// This file provides a single, shared set of stub classes for FFI types
// to be used by web-safe implementations, avoiding name collisions.

/// A web-safe stub for the native `dart:ffi` NativeType.
class NativeType {}

/// A web-safe stub for the native `dart:ffi` Pointer.
/// The generic constraint matches the real dart:ffi Pointer.
class Pointer<T extends NativeType> {
  // A dummy Pointer class for the web.
  // It holds no actual memory address.
}

/// A web-safe stub for the native `dart:ffi` Float.
class Float extends NativeType {}
