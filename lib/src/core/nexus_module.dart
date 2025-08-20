import 'package:nexus/src/core/nexus_world.dart';
import 'package:nexus/src/core/providers/entity_provider.dart';
import 'package:nexus/src/core/providers/system_provider.dart';

/// Represents a self-contained feature module, acting as an assembler.
///
/// The module's primary role is to aggregate various providers
/// ([SystemProvider], [EntityProvider], etc.) that define the actual
/// behavior and data of the feature. This keeps the module class clean
/// and focused on composition rather than implementation.
abstract class NexusModule {
  /// A list of providers that supply the systems for this module.
  List<SystemProvider> get systemProviders;

  /// A list of providers that create the entities for this module.
  List<EntityProvider> get entityProviders;

  /// A lifecycle method called when the module is loaded into the world.
  ///
  /// This is the ideal place to register services with GetIt or perform
  /// any other one-time setup for the module.
  void onLoad(NexusWorld world) {}

  /// A lifecycle method called when the world is being cleared or the module
  /// is unloaded.
  ///
  /// This should be used to clean up any resources.
  void onUnload(NexusWorld world) {}
}
