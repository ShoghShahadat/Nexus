import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// The base class for all Systems in the Nexus architecture.
///
/// A System contains all the logic. It operates on a collection of Entities
/// that have a specific set of Components.
abstract class System {
  /// A reference to the world, providing access to all entities.
  late final NexusWorld world;

  /// A list of component types that this system is interested in.
  /// The system will only process entities that have all of these components.
  final List<Type> componentTypes;

  /// Creates a new system that targets entities with the specified components.
  System(this.componentTypes);

  /// Called once per frame/tick for each entity that matches the
  /// `componentTypes` filter.
  ///
  /// [entity] is the entity being processed.
  /// [dt] is the delta time, the time elapsed since the last frame in seconds.
  void update(Entity entity, double dt);

  /// A lifecycle method called when the system is added to the world.
  void onAddedToWorld(NexusWorld world) {
    this.world = world;
  }

  /// A lifecycle method called when an entity that matches this system's
  /// component filter is removed from the world.
  /// Use this to clean up any resources associated with the entity.
  void onEntityRemoved(Entity entity) {}

  /// A lifecycle method called when the system is removed from the world.
  void onRemovedFromWorld() {}
}
