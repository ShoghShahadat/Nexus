import 'package:nexus/src/core/nexus_world.dart';
import 'package:nexus/src/core/system.dart';

/// Represents a self-contained feature module in the Nexus architecture.
///
/// Each module is responsible for registering its own systems and can provide
/// builders for the entities it manages. This structure allows large teams to
/// work on isolated features in parallel with minimal code conflicts.
abstract class NexusModule {
  /// A list of systems that this module contributes to the world.
  ///
  /// These systems will be added to the [NexusWorld] when the module is loaded.
  List<System> get systems;

  /// A lifecycle method called when the module is loaded into the world.
  ///
  /// This is the ideal place to register services with GetIt, set up
  /// event bus listeners, or perform any other one-time setup for the module.
  void onLoad(NexusWorld world) {}

  /// A lifecycle method called when the world is being cleared or the module
  /// is unloaded.
  ///
  /// This should be used to clean up any resources, such as closing streams
  /// or unregistering services.
  void onUnload(NexusWorld world) {}
}
