import 'package:flutter/widgets.dart';

/// An event that is fired when a user selects a new shape to morph into.
/// This is part of the core library to allow any module to fire or listen to it.
class ShapeSelectedEvent {
  /// The path of the shape that was selected.
  final Path targetPath;

  ShapeSelectedEvent(this.targetPath);
}
