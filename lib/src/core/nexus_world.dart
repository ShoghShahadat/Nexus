import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  /// A convenience getter to access the automatically created root entity.
  /// یک getter راحت برای دسترسی به موجودیت root که به صورت خودکار ساخته شده است.
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
    // Automatically create and add the root entity upon world creation.
    // به صورت خودکار موجودیت root را هنگام ساخت دنیا ایجاد و اضافه می‌کند.
    _createRootEntity();
  }

  /// Creates and adds the default root entity to the world.
  void _createRootEntity() {
    rootEntity = Entity();
    rootEntity.addComponents([
      TagsComponent({'root'}),
      // Initialize with default values; ResponsivenessSystem will update it.
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
