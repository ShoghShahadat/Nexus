// FILE: packages/nexus/lib/src/core/nexus_world.dart
// (English comments for code clarity)
// FRAMEWORK-LEVEL FIX: This file contains the core logic change to prevent race conditions.

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
/// This class has been re-engineered with a robust, multi-stage initialization
/// process to completely eliminate race conditions during startup.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  late final Entity rootEntity;
  GarbageCollectorSystem? _gc;

  final Set<EntityId> _removedEntityIdsThisFrame = {};

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_systems);

  NexusWorld({GetIt? serviceLocator, EventBus? eventBus})
      : services = serviceLocator ?? GetIt.instance {
    this.eventBus = eventBus ?? EventBus();
    if (!services.isRegistered<EventBus>()) {
      services.registerSingleton<EventBus>(this.eventBus);
    }
    _createRootEntity();
  }

  void _createRootEntity() {
    rootEntity = Entity();
    rootEntity.addComponents([
      TagsComponent({'root'}),
      ScreenInfoComponent(
          width: 0, height: 0, orientation: ScreenOrientation.portrait),
      LifecyclePolicyComponent(isPersistent: true),
    ]);
    addEntity(rootEntity);
  }

  /// **RE-ENGINEERED INITIALIZATION LIFECYCLE**
  Future<void> init() async {
    // Stage 1: Load all modules and create all initial entities from providers.
    // This ensures the world's structure is fully defined before any logic runs.
    for (final module in _modules) {
      module.onLoad(this);
      for (final provider in module.entityProviders) {
        provider.createEntities(this);
      }
    }

    // Stage 2: Initialize all systems.
    // This is now guaranteed to run *after* all initial entities (like containers) exist.
    // This is where PersistenceSystem will now safely run and load data.
    for (final system in _systems) {
      await system.init();
    }

    // Note: The PersistenceSystem is now responsible for firing the DataLoadedEvent
    // at the end of its `_load` method, signaling the final step of initialization.
  }

  void loadModule(NexusModule module) {
    _modules.add(module);
    for (final provider in module.systemProviders) {
      for (final system in provider.systems) {
        addSystem(system);
      }
    }
  }

  void addEntity(Entity entity) {
    if (_entities.containsKey(entity.id)) {
      if (kDebugMode) {
        print(
            '[NexusWorld] WARNING: An entity with ID ${entity.id} already exists. Overwriting.');
      }
    }
    _entities[entity.id] = entity;
    for (final system in _systems) {
      if (system.matches(entity)) {
        system.onEntityAdded(entity);
      }
    }
  }

  Entity? removeEntity(EntityId id) {
    final entity = _entities.remove(id);
    if (entity != null) {
      _removedEntityIdsThisFrame.add(id);
      for (final system in _systems) {
        system.onEntityRemoved(entity);
      }
      entity.dispose();
    }
    return entity;
  }

  Set<EntityId> getAndClearRemovedEntities() {
    final Set<EntityId> removed = Set.from(_removedEntityIdsThisFrame);
    _removedEntityIdsThisFrame.clear();
    return removed;
  }

  void addSystem(System system) {
    if (system is GarbageCollectorSystem) {
      _gc = system;
    }
    _systems.add(system);
    system.onAddedToWorld(this);
  }

  void removeSystem(System system) {
    if (system is GarbageCollectorSystem) {
      _gc = null;
    }
    if (_systems.remove(system)) {
      system.onRemovedFromWorld();
    }
  }

  void update(double dt) {
    // Run the garbage collector first, if it's enabled.
    _gc?.runGc(dt);

    final entitiesList = List<Entity>.from(_entities.values);
    for (final system in _systems) {
      for (final entity in entitiesList) {
        if (_entities.containsKey(entity.id) && system.matches(entity)) {
          system.update(entity, dt);
        }
      }
    }
  }

  void clear() {
    for (final module in _modules) {
      module.onUnload(this);
    }
    for (final system in _systems) {
      system.onRemovedFromWorld();
    }
    for (final entity in _entities.values) {
      entity.dispose();
    }
    _entities.clear();
    _systems.clear();
    _modules.clear();
    eventBus.destroy();
    _removedEntityIdsThisFrame.clear();
  }
}
