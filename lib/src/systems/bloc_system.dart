import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexus/src/components/bloc_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that listens to state changes from `BlocComponent`s.
///
/// This system is a bridge that allows the reactive BLoC pattern to drive
/// changes in the data-oriented ECS world.
abstract class BlocSystem extends System {
  final Map<EntityId, StreamSubscription> _subscriptions = {};

  /// Creates a new BlocSystem.
  BlocSystem()
      : super([]); // componentTypes is empty as we use custom matching.

  /// Overridden to specifically target entities that have a `BlocComponent`.
  /// This is the key to solving the generic type matching issue.
  @override
  bool matches(Entity entity) {
    return entity.allComponents.any((c) => c is BlocComponent);
  }

  /// This method is now only called for entities that are guaranteed to have
  /// a `BlocComponent`, thanks to our custom `matches` logic.
  @override
  void update(Entity entity, double dt) {
    if (_subscriptions.containsKey(entity.id)) return;

    final blocComponent = entity.allComponents
        .firstWhere((c) => c is BlocComponent) as BlocComponent;

    debugPrint(
        '[BlocSystem] Found BlocComponent on Entity(${entity.id}). Setting up subscription.');

    // 1. Immediately process the BLoC's current state to show the initial UI.
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
  void onStateChange(Entity entity, dynamic state);

  @override
  void onEntityRemoved(Entity entity) {
    if (_subscriptions.containsKey(entity.id)) {
      debugPrint(
          '[BlocSystem] Entity(${entity.id}) removed. Cancelling subscription.');
      _subscriptions.remove(entity.id)?.cancel();
    }
    super.onEntityRemoved(entity);
  }

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
