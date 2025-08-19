import 'dart:async';

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

    final blocComponent = entity.get<BlocComponent>();
    if (blocComponent == null) return;

    _subscriptions[entity.id] = blocComponent.bloc.stream.listen((state) {
      // Ensure the entity still exists before processing the state change.
      if (world.entities.containsKey(entity.id)) {
        onStateChange(entity, state);
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
    _subscriptions.remove(entity.id)?.cancel();
    super.onEntityRemoved(entity);
  }

  /// Overridden to clean up all subscriptions when the system is removed.
  @override
  void onRemovedFromWorld() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.onRemovedFromWorld();
  }
}
