import 'package:nexus/src/core/nexus_world.dart';

/// An interface for classes that create and provide entities for a module.
///
/// This allows the entity creation logic to be separated from the main
/// module definition, promoting cleaner and more organized code.
abstract class EntityProvider {
  /// Called by the [NexusModule] to create and add all necessary entities
  /// to the world.
  void createEntities(NexusWorld world);
}
