import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/event_bus.dart';
import 'package:nexus/src/core/nexus_module.dart';
import 'package:nexus/src/core/system.dart';

/// Manages all the entities, systems, and modules in the Nexus world.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  // یک Set برای نگهداری ID موجودیت‌هایی که در این فریم حذف شده‌اند.
  final Set<EntityId> _removedEntityIdsThisFrame = {};

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_systems);

  NexusWorld({GetIt? serviceLocator, EventBus? eventBus})
      : services = serviceLocator ?? GetIt.instance {
    this.eventBus = eventBus ?? EventBus();
    services.registerSingleton<EventBus>(this.eventBus);
  }

  /// Loads a module into the world, registering its systems and creating its entities.
  void loadModule(NexusModule module) {
    _modules.add(module);

    // Load systems from all system providers.
    for (final provider in module.systemProviders) {
      for (final system in provider.systems) {
        addSystem(system);
      }
    }

    // Call the module's onLoad lifecycle method.
    module.onLoad(this);

    // Create entities from all entity providers.
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
      // اضافه کردن ID موجودیت حذف شده به لیست موقت
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

  /// موجودیت‌های حذف شده در این فریم را برمی‌گرداند و لیست را پاک می‌کند.
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
    _removedEntityIdsThisFrame.clear(); // پاک کردن لیست موجودیت‌های حذف شده
  }
}
