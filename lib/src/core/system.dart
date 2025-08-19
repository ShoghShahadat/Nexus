import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// The base class for all Systems in the Nexus architecture.
///
/// A System contains all the logic. It operates on a collection of Entities
/// that have a specific set of Components.
abstract class System {
  /// A reference to the world, providing access to all entities.
  late final NexusWorld world;

  /// Provides convenient access to the service locator.
  GetIt get services => world.services;

  /// A list of component types used by the default `matches` implementation.
  final List<Type> componentTypes;

  /// Creates a new system.
  System(this.componentTypes);

  /// Checks if an entity is a match for this system.
  /// The default implementation checks if the entity has all `componentTypes`.
  /// Systems can override this for more complex logic (e.g., generics).
  bool matches(Entity entity) {
    return entity.hasAll(componentTypes);
  }

  /// Called once per frame/tick for each entity that this system `matches`.
  ///
  /// [entity] is the entity being processed.
  /// [dt] is the delta time, the time elapsed since the last frame in seconds.
  void update(Entity entity, double dt);

  /// A lifecycle method called when the system is added to the world.
  void onAddedToWorld(NexusWorld world) {
    this.world = world;
  }

  /// A lifecycle method called when a matching entity is removed from the world.
  void onEntityRemoved(Entity entity) {}

  /// A lifecycle method called when the system is removed from the world.
  void onRemovedFromWorld() {}
}
