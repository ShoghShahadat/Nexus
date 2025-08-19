import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// Manages all the entities and systems in the Nexus world.
///
/// The NexusWorld is the central hub of the architecture. It holds all the
/// application objects (Entities), the logic controllers (Systems), and a
/// service locator for dependency injection. It is responsible for running
/// the main update loop and notifying the UI of changes.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final GetIt services;

  /// A notifier that signals to the UI when a visual change has occurred
  /// and a rebuild is necessary.
  final ChangeNotifier worldNotifier = ChangeNotifier();

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_systems);

  NexusWorld({GetIt? serviceLocator})
      : services = serviceLocator ?? GetIt.instance;

  void addEntity(Entity entity) {
    _entities[entity.id] = entity;
  }

  Entity? removeEntity(EntityId id) {
    final entity = _entities.remove(id);
    if (entity != null) {
      for (final system in _systems) {
        if (system.matches(entity)) {
          system.onEntityRemoved(entity);
        }
      }
      // Notify UI that an entity was removed
      worldNotifier.notifyListeners();
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
  ///
  /// It iterates through all registered systems and calls their `update` method
  /// for each entity that the system `matches`.
  void update(double dt) {
    // The logic loop runs independently of the UI render loop.
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
    _entities.clear();
    _systems.clear();
    worldNotifier.notifyListeners();
  }
}
