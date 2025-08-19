import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// Manages all the entities and systems in the Nexus world.
///
/// The NexusWorld is the central hub of the architecture. It holds all the
/// application objects (Entities), the logic controllers (Systems), and a
/// service locator for dependency injection. It is responsible for running
/// the main update loop, which drives the application's state forward.
class NexusWorld {
  /// A map of all entities in the world, indexed by their unique ID.
  final Map<EntityId, Entity> _entities = {};

  /// A list of all systems that process the entities.
  final List<System> _systems = [];

  /// The service locator instance for dependency injection.
  /// Systems can access this to get dependencies like repositories or services.
  final GetIt services;

  /// A read-only view of the entities in the world.
  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);

  /// A read-only view of the systems in the world.
  List<System> get systems => List.unmodifiable(_systems);

  /// Creates a new world.
  ///
  /// Optionally accepts a [serviceLocator]. If not provided, it will use
  /// the global `GetIt.instance`.
  NexusWorld({GetIt? serviceLocator})
      : services = serviceLocator ?? GetIt.instance;

  /// Adds an entity to the world.
  void addEntity(Entity entity) {
    _entities[entity.id] = entity;
  }

  /// Removes an entity from the world using its ID.
  /// Notifies relevant systems that the entity has been removed.
  /// Returns the removed entity, or null if it wasn't found.
  Entity? removeEntity(EntityId id) {
    final entity = _entities.remove(id);
    if (entity != null) {
      for (final system in _systems) {
        if (entity.hasAll(system.componentTypes)) {
          system.onEntityRemoved(entity);
        }
      }
    }
    return entity;
  }

  /// Adds a system to the world.
  /// The system's `onAddedToWorld` lifecycle method is called.
  void addSystem(System system) {
    _systems.add(system);
    system.onAddedToWorld(this);
  }

  /// Removes a system from the world.
  /// The system's `onRemovedFromWorld` lifecycle method is called.
  void removeSystem(System system) {
    if (_systems.remove(system)) {
      system.onRemovedFromWorld();
    }
  }

  /// The main update loop for the world.
  ///
  /// This method should be called once per frame (e.g., from a `Ticker` in Flutter).
  /// It iterates through all registered systems and calls their `update` method
  /// for each entity that matches the system's component requirements.
  ///
  /// [dt] is the delta time in seconds since the last update.
  void update(double dt) {
    // A copy is made to prevent issues if systems modify the entity list during update.
    final entities = List<Entity>.from(_entities.values);
    for (final system in _systems) {
      for (final entity in entities) {
        // Ensure the entity still exists in the world before updating.
        if (_entities.containsKey(entity.id) &&
            entity.hasAll(system.componentTypes)) {
          system.update(entity, dt);
        }
      }
    }
  }

  /// Clears all entities and systems from the world.
  void clear() {
    for (final system in _systems) {
      system.onRemovedFromWorld();
    }
    _entities.clear();
    _systems.clear();
  }
}
