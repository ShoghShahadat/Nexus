import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  final Set<EntityId> _removedEntityIdsThisFrame = {};

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_systems);

  NexusWorld({GetIt? serviceLocator, EventBus? eventBus})
      : services = serviceLocator ?? GetIt.instance {
    this.eventBus = eventBus ?? EventBus();
    services.registerSingleton<EventBus>(this.eventBus);
  }

  // --- NEW: Asynchronous initialization method ---
  /// Initializes the world, running any async setup required by its systems.
  /// This should be called before the main update loop begins.
  Future<void> init() async {
    for (final system in _systems) {
      await system.init();
    }
  }
  // --- END NEW ---

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
        if (system.matches(entity)) {
          system.onEntityRemoved(entity);
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
    _systems.add(system);
    system.onAddedToWorld(this);
  }

  void removeSystem(System system) {
    if (_systems.remove(system)) {
      system.onRemovedFromWorld();
    }
  }

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
