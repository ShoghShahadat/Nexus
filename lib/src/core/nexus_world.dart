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
    addEntity(rootEntity);

    rootEntity.addComponents([
      TagsComponent({'root'}),
      ScreenInfoComponent(
          width: 0, height: 0, orientation: ScreenOrientation.portrait),
      LifecyclePolicyComponent(isPersistent: true),
    ]);
  }

  Future<void> init() async {
    // CRITICAL FIX: The module's onLoad is now called in `loadModule`.
    // We only need to create entities here now.
    // اصلاح حیاتی: متد onLoad ماژول اکنون در `loadModule` فراخوانی می‌شود.
    // در اینجا فقط نیاز به ایجاد موجودیت‌ها داریم.
    for (final module in _modules) {
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

    // --- CRITICAL FIX: Call onLoad *before* processing any providers. ---
    // This ensures all services are registered before systems that depend on them are added.
    // اصلاح حیاتی: متد onLoad را *قبل* از پردازش هر provider فراخوانی می‌کنیم.
    // این کار تضمین می‌کند که تمام سرویس‌ها قبل از اضافه شدن سیستم‌های وابسته به آنها، ثبت شده‌اند.
    module.onLoad(this);

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
    entity.setWorld(this);
    _entities[entity.id] = entity;

    for (final system in _allSystems) {
      system.onEntityAdded(entity);

      if (system is UpdateSystem && system.matches(entity)) {
        system.addEntityToCache(entity);
      }
    }
  }

  Entity? removeEntity(EntityId id) {
    final entity = _entities.remove(id);
    if (entity != null) {
      _removedEntityIdsThisFrame.add(id);

      for (final system in _allSystems) {
        system.onEntityRemoved(entity);

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

  void addSystem(System system) {
    if (system is GarbageCollectorSystem) {
      _gc = system;
    }
    _allSystems.add(system);
    system.onAddedToWorld(this);

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

  void notifyComponentChange(
      Entity entity, Component? oldComponent, Component? newComponent) {
    final componentType =
        newComponent?.runtimeType ?? oldComponent!.runtimeType;

    final interestedSystems = _componentSubscriptions[componentType];

    if (interestedSystems == null) return;

    for (final system in List<ReactiveSystem>.from(interestedSystems)) {
      if (newComponent == null && oldComponent != null) {
        system.onComponentRemoved(entity, oldComponent);
      } else if (newComponent != null) {
        system.onComponentChanged(entity, oldComponent, newComponent);
      }
    }
  }

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
