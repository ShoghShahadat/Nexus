/// This file acts as a conditional export.
/// It provides the native implementation for mobile/desktop (where dart:io is available)
/// and a web-safe stub implementation for the web (where dart:html is available).

export 'gpu_context_web.dart' if (dart.library.io) 'gpu_context_native.dart';
