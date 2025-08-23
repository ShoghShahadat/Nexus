import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/lifecycle_policy_component.dart';
import 'package:nexus/src/core/utils/frequency.dart';
import 'package:nexus/src/systems/garbage_collector_system.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
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

  Future<void> init() async {
    for (final system in _systems) {
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
    module.onLoad(this);
    for (final provider in module.entityProviders) {
      provider.createEntities(this);
    }
  }

  void addEntity(Entity entity) {
    if (kDebugMode &&
        !entity.has<LifecyclePolicyComponent>() &&
        entity.id != rootEntity.id) {
      debugPrint(
          '[NexusWorld] WARNING: Entity ID ${entity.id} was added without a LifecyclePolicyComponent. This is highly discouraged.');
    }
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

  void addSystems(List<System> systems) {
    for (final system in systems) {
      addSystem(system);
    }
  }

  void removeSystem(System system) {
    if (system is GarbageCollectorSystem) {
      _gc = null;
    }
    if (_systems.remove(system)) {
      system.onRemovedFromWorld();
    }
  }

  void removeSystems(List<System> systems) {
    for (final system in systems) {
      removeSystem(system);
    }
  }

  Entity createSpawner({
    required Entity Function() prefab,
    Frequency frequency = Frequency.never,
    bool wantsToFire = true,
    bool Function()? condition,
    PositionComponent? position,
    String? tag,
  }) {
    final spawnerEntity = Entity();
    final components = <Component>[];

    if (tag != null) {
      components.add(TagsComponent({tag}));
    }

    components.add(position ?? PositionComponent(x: 0, y: 0));
    components.add(SpawnerComponent(
      prefab: prefab,
      frequency: frequency,
      wantsToFire: wantsToFire,
      condition: condition,
    ));

    // --- FIX: Automatically add a persistent lifecycle policy to all spawners. ---
    // --- اصلاح: یک خط مشی چرخه عمر دائمی به صورت خودکار به همه spawnerها اضافه می‌شود. ---
    components.add(LifecyclePolicyComponent(isPersistent: true));

    spawnerEntity.addComponents(components);
    addEntity(spawnerEntity);
    return spawnerEntity;
  }

  void update(double dt) {
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
