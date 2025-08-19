import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// Manages all the entities and systems in the Nexus world.
///
/// The NexusWorld is the central hub of the architecture. It holds all the
/// application objects (Entities), the logic controllers (Systems), and a
/// service locator for dependency injection. It is responsible for running
/// the main update loop.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final GetIt services;

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_systems);

  NexusWorld({GetIt? serviceLocator})
      : services = serviceLocator ?? GetIt.instance;

  void addEntity(Entity entity) {
    _entities[entity.id] = entity;
    // Notify systems that a new entity has been added.
    for (final system in _systems) {
      if (system.matches(entity)) {
        system.onEntityAdded(entity);
      }
    }
  }

  Entity? removeEntity(EntityId id) {
    final entity = _entities.remove(id);
    if (entity != null) {
      // Notify systems before disposing the entity.
      for (final system in _systems) {
        if (system.matches(entity)) {
          system.onEntityRemoved(entity);
        }
      }
      // When removing an entity, also dispose it to release listeners.
      entity.dispose();
    }
    return entity;
  }

  void addSystem(System system) {
    _systems.add(system);
    system.onAddedToWorld(this);
  }

  void removeSystem(System system) {
    if (_systems.remove(system)) {
      system.onRemovedFromWorld();
    }
  }

  /// The main update loop for the world.
  void update(double dt) {
    final entities = List<Entity>.from(_entities.values);
    for (final system in _systems) {
      for (final entity in entities) {
        if (_entities.containsKey(entity.id) && system.matches(entity)) {
          system.update(entity, dt);
        }
      }
    }
  }

  void clear() {
    for (final system in _systems) {
      system.onRemovedFromWorld();
    }
    for (final entity in _entities.values) {
      entity.dispose();
    }
    _entities.clear();
    _systems.clear();
  }
}
