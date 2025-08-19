import 'package:nexus/src/core/system.dart';

/// An interface for classes that provide a list of systems.
///
/// This allows a [NexusModule] to be composed of multiple, smaller,
/// single-responsibility providers, enhancing modularity.
abstract class SystemProvider {
  /// A list of systems to be added to the world.
  List<System> get systems;
}
