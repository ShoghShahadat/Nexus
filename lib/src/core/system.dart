import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/nexus_world.dart';
import 'package:meta/meta.dart';
import 'package:nexus/src/core/component.dart';

/// --- NEW: Base class for all systems. ---
abstract class System {
  late final NexusWorld world;
  final List<StreamSubscription> _subscriptions = [];
  GetIt get services => world.services;

  void listen<T>(void Function(T event) onData) {
    final subscription = world.eventBus.on<T>(onData);
    _subscriptions.add(subscription);
  }

  Future<void> init() async {}

  void onAddedToWorld(NexusWorld world) {
    this.world = world;
  }

  void onRemovedFromWorld() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // --- MODIFIED: Moved from UpdateSystem to the base System class ---
  // This makes entity lifecycle hooks available to ALL system types.
  /// Called when any entity is added to the world.
  /// A system can override this to react, e.g., to cache the entity.
  void onEntityAdded(Entity entity) {}

  /// Called just before any entity is removed from the world.
  /// A system can override this to perform cleanup for that entity.
  void onEntityRemoved(Entity entity) {}
}

/// --- NEW: A system that runs its logic every frame. ---
/// Ideal for physics, animation, timers, or any continuous simulation.
abstract class UpdateSystem extends System {
  final List<Entity> _matchedEntities = [];
  List<Entity> get matchedEntities => List.unmodifiable(_matchedEntities);

  bool matches(Entity entity);

  void update(Entity entity, double dt);

  void run(double dt) {
    for (final entity in List<Entity>.from(_matchedEntities)) {
      if (world.entities.containsKey(entity.id)) {
        update(entity, dt);
      }
    }
  }

  @override
  void onRemovedFromWorld() {
    _matchedEntities.clear();
    super.onRemovedFromWorld();
  }

  @internal
  void addEntityToCache(Entity entity) {
    if (!_matchedEntities.contains(entity)) {
      _matchedEntities.add(entity);
    }
  }

  @internal
  void removeEntityFromCache(Entity entity) {
    _matchedEntities.remove(entity);
  }
}

/// --- NEW: A system that only runs in reaction to component changes. ---
/// This is the most efficient type of system for logic that isn't time-dependent.
abstract class ReactiveSystem extends System {
  /// Defines which component types this system is interested in.
  /// The system's logic will only be triggered when one of these components
  /// is added, updated, or removed from an entity.
  Set<Type> get subscribedComponentTypes;

  /// Called when a subscribed component is added or updated on an entity.
  /// Provides the entity, the previous state of the component (if any),
  /// and the new state of the component.
  void onComponentChanged(
      Entity entity, Component? oldComponent, Component newComponent);

  /// Called when a subscribed component is removed from an entity.
  void onComponentRemoved(Entity entity, Component removedComponent);
}
