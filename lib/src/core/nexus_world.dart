import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/event_bus.dart';
import 'package:nexus/src/core/nexus_module.dart';
import 'package:nexus/src/core/system.dart';

/// Manages all the entities and systems in the Nexus world.
///
/// The NexusWorld is the central hub of the architecture. It holds all the
/// application objects (Entities), the logic controllers (Systems), and a
/// service locator for dependency injection. It is responsible for running
/// the main update loop and managing modules.
class NexusWorld {
  final Map<EntityId, Entity> _entities = {};
  final List<System> _systems = [];
  final List<NexusModule> _modules = [];
  final GetIt services;
  late final EventBus eventBus;

  Map<EntityId, Entity> get entities => Map.unmodifiable(_entities);
  List<System> get systems => List.unmodifiable(_systems);

  NexusWorld({GetIt? serviceLocator, EventBus? eventBus})
      : services = serviceLocator ?? GetIt.instance {
    this.eventBus = eventBus ?? EventBus();
    services.registerSingleton<EventBus>(this.eventBus);
  }

  /// Loads a module into the world.
  ///
  /// This adds all the module's systems to the world and calls the module's
  /// `onLoad` lifecycle method.
  void loadModule(NexusModule module) {
    _modules.add(module);
    for (final system in module.systems) {
      addSystem(system);
    }
    module.onLoad(this);
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
      for (final system in _systems) {
        if (system.matches(entity)) {
          system.onEntityRemoved(entity);
        }
      }
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
  }
}
