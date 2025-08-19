import 'dart:async';

import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:nexus/src/components/bloc_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that listens to state changes from `BlocComponent`s.
///
/// This system is a bridge that allows the reactive BLoC pattern to drive
/// changes in the data-oriented ECS world. It subscribes to the stream of
/// states from any entity's `BlocComponent`.
///
/// Subclasses should override `onStateChange` to implement logic that
/// responds to new states.
abstract class BlocSystem extends System {
  final Map<EntityId, StreamSubscription> _subscriptions = {};

  /// Creates a new BlocSystem.
  /// It automatically targets entities with a `BlocComponent`.
  BlocSystem() : super([BlocComponent]);

  /// This method is called by the `NexusWorld` for each matching entity.
  /// It sets up a subscription to the BLoC's state stream if one doesn't
  /// already exist for the entity.
  @override
  void update(Entity entity, double dt) {
    if (_subscriptions.containsKey(entity.id)) return;
    debugPrint(
        '[BlocSystem] First update for Entity(${entity.id}). Setting up subscription.');

    final blocComponent = entity.get<BlocComponent>();
    if (blocComponent == null) {
      debugPrint(
          '[BlocSystem] Entity(${entity.id}) has no BlocComponent. Skipping.');
      return;
    }

    // --- LOGGING ---
    // 1. Immediately process the BLoC's current state.
    debugPrint(
        '[BlocSystem] Entity(${entity.id}) Processing initial state: ${blocComponent.bloc.state}');
    onStateChange(entity, blocComponent.bloc.state);

    // 2. Subscribe to all future state changes.
    _subscriptions[entity.id] = blocComponent.bloc.stream.listen((state) {
      debugPrint(
          '[BlocSystem] Entity(${entity.id}) received new state from stream: $state');
      if (world.entities.containsKey(entity.id)) {
        onStateChange(entity, state);
      } else {
        debugPrint(
            '[BlocSystem] Entity(${entity.id}) no longer in world. Ignoring state change.');
      }
    });
  }

  /// The core logic method. This is called whenever a BLoC instance
  /// managed by this system emits a new state.
  ///
  /// [entity] is the entity whose `BlocComponent` emitted the state.
  /// [state] is the new state object.
  void onStateChange(Entity entity, dynamic state);

  /// Cleans up the subscription when a relevant entity is removed.
  @override
  void onEntityRemoved(Entity entity) {
    debugPrint(
        '[BlocSystem] Entity(${entity.id}) removed. Cancelling subscription.');
    _subscriptions.remove(entity.id)?.cancel();
    super.onEntityRemoved(entity);
  }

  /// Overridden to clean up all subscriptions when the system is removed.
  @override
  void onRemovedFromWorld() {
    debugPrint(
        '[BlocSystem] System removed from world. Clearing all subscriptions.');
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.onRemovedFromWorld();
  }
}
