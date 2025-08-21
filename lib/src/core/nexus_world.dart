import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/utils/frequency.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  late final Entity rootEntity;

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
    ]);
    addEntity(rootEntity);
  }

  /// Initializes the world, running any async setup required by its systems.
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
    _systems.add(system);
    system.onAddedToWorld(this);
  }

  void addSystems(List<System> systems) {
    for (final system in systems) {
      addSystem(system);
    }
  }

  void removeSystem(System system) {
    if (_systems.remove(system)) {
      system.onRemovedFromWorld();
    }
  }

  void removeSystems(List<System> systems) {
    for (final system in systems) {
      removeSystem(system);
    }
  }

  // *** NEW: A helper method to easily create and add a spawner entity. ***
  // *** جدید: یک متد کمکی برای ساخت و افزودن آسان یک موجودیت سازنده. ***
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

    spawnerEntity.addComponents(components);
    addEntity(spawnerEntity);
    return spawnerEntity;
  }

  void update(double dt) {
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
