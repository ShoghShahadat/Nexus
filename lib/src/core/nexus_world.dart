// FILE: packages/nexus/lib/src/core/nexus_world.dart
// (English comments for code clarity)
// --- ARCHITECTURAL UPGRADE: From Proactive to Fully Reactive Core ---

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
///
/// --- NEW REACTIVE ARCHITECTURE ---
/// The world now acts as a central dispatcher. It maintains a subscription map
/// linking component types to the reactive systems that care about them.
/// When a component changes, the world notifies only the relevant systems,
/// leading to massive performance gains.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  // --- NEW: Segregated lists for different system types ---
  final List<System> _allSystems = [];
  final List<UpdateSystem> _updateSystems = [];
  final Map<Type, List<ReactiveSystem>> _componentSubscriptions = {};

  late final Entity rootEntity;
  GarbageCollectorSystem? _gc;

  final Set<EntityId> _removedEntityIdsThisFrame = {};

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_allSystems);

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
    // CRITICAL FIX for LateInitializationError:
    // FIRST, add the entity to the world so its `world` property is set.
    // THEN, add components to it. Now it's safe because `addComponents`
    // can access `entity.world`.
    // اصلاح حیاتی برای خطای LateInitializationError:
    // ابتدا، موجودیت را به دنیا اضافه می‌کنیم تا پراپرتی `world` آن تنظیم شود.
    // سپس، کامپوننت‌ها را به آن اضافه می‌کنیم. اکنون این کار امن است زیرا
    // `addComponents` می‌تواند به `entity.world` دسترسی داشته باشد.
    addEntity(rootEntity);

    rootEntity.addComponents([
      TagsComponent({'root'}),
      ScreenInfoComponent(
          width: 0, height: 0, orientation: ScreenOrientation.portrait),
      LifecyclePolicyComponent(isPersistent: true),
    ]);
  }

  Future<void> init() async {
    for (final module in _modules) {
      module.onLoad(this);
      for (final provider in module.entityProviders) {
        provider.createEntities(this);
      }
    }
    for (final system in _allSystems) {
      await system.init();
    }
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
    // --- NEW: Assign world reference before adding ---
    entity.setWorld(this);
    _entities[entity.id] = entity;

    // --- MODIFIED: Call onEntityAdded for ALL systems ---
    for (final system in _allSystems) {
      // General lifecycle hook for all systems
      system.onEntityAdded(entity);

      // Specific logic for UpdateSystems
      if (system is UpdateSystem && system.matches(entity)) {
        system.addEntityToCache(entity);
      }
    }
  }

  Entity? removeEntity(EntityId id) {
    final entity = _entities.remove(id);
    if (entity != null) {
      _removedEntityIdsThisFrame.add(id);

      // --- MODIFIED: Call onEntityRemoved for ALL systems ---
      for (final system in _allSystems) {
        // General lifecycle hook for all systems
        system.onEntityRemoved(entity);

        // Specific logic for UpdateSystems
        if (system is UpdateSystem) {
          system.removeEntityFromCache(entity);
        }
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

  /// --- MODIFIED: Now registers systems based on their type ---
  void addSystem(System system) {
    if (system is GarbageCollectorSystem) {
      _gc = system;
    }
    _allSystems.add(system);
    system.onAddedToWorld(this);

    // --- NEW: Handle system specialization ---
    if (system is UpdateSystem) {
      _updateSystems.add(system);
      for (final entity in _entities.values) {
        if (system.matches(entity)) {
          system.addEntityToCache(entity);
        }
      }
    } else if (system is ReactiveSystem) {
      for (final componentType in system.subscribedComponentTypes) {
        _componentSubscriptions
            .putIfAbsent(componentType, () => [])
            .add(system);
      }
    }
  }

  void removeSystem(System system) {
    if (system is GarbageCollectorSystem) {
      _gc = null;
    }
    if (_allSystems.remove(system)) {
      // --- NEW: Also remove from specialized lists/maps ---
      if (system is UpdateSystem) {
        _updateSystems.remove(system);
      } else if (system is ReactiveSystem) {
        for (final componentType in system.subscribedComponentTypes) {
          _componentSubscriptions[componentType]?.remove(system);
        }
      }
      system.onRemovedFromWorld();
    }
  }

  /// --- NEW & MODIFIED: The central dispatcher, now non-generic and more robust. ---
  /// It uses runtime types to notify the correct systems, fixing the type inference error.
  void notifyComponentChange(
      Entity entity, Component? oldComponent, Component? newComponent) {
    // Determine the component type from the arguments at runtime.
    final componentType =
        newComponent?.runtimeType ?? oldComponent!.runtimeType;

    final interestedSystems = _componentSubscriptions[componentType];

    if (interestedSystems == null) return;

    // Use a copy of the list to avoid concurrent modification issues.
    for (final system in List<ReactiveSystem>.from(interestedSystems)) {
      if (newComponent == null && oldComponent != null) {
        // This is a removal
        system.onComponentRemoved(entity, oldComponent);
      } else if (newComponent != null) {
        // This is an addition or update
        system.onComponentChanged(entity, oldComponent, newComponent);
      }
    }
  }

  /// --- THE ULTIMATELY OPTIMIZED UPDATE LOOP ---
  /// Now, it only iterates over the systems that absolutely need to run every frame.
  void update(double dt) {
    _gc?.runGc(dt);

    for (final system in _updateSystems) {
      system.run(dt);
    }
  }

  void clear() {
    for (final module in _modules) {
      module.onUnload(this);
    }
    for (final system in _allSystems) {
      system.onRemovedFromWorld();
    }
    for (final entity in _entities.values) {
      entity.dispose();
    }
    _entities.clear();
    _allSystems.clear();
    _updateSystems.clear();
    _componentSubscriptions.clear();
    _modules.clear();
    eventBus.destroy();
    _removedEntityIdsThisFrame.clear();
  }
}
