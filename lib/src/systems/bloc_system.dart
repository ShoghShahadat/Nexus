import 'dart:async';

import 'package:nexus/src/components/bloc_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A system that listens to state changes from `BlocComponent`s.
abstract class BlocSystem extends System {
  final Map<EntityId, StreamSubscription> _subscriptions = {};

  /// Overridden to specifically target entities that have a `BlocComponent`.
  @override
  bool matches(Entity entity) {
    return entity.has<BlocComponent>();
  }

  /// This method is now only called for entities that are guaranteed to have
  /// a `BlocComponent`, thanks to our `matches` logic.
  @override
  void update(Entity entity, double dt) {
    if (_subscriptions.containsKey(entity.id)) return;

    final blocComponent = entity.get<BlocComponent>()!;

    // 1. Immediately process the BLoC's current state.
    onStateChange(entity, blocComponent.bloc.state);

    // 2. Subscribe to all future state changes.
    _subscriptions[entity.id] = blocComponent.bloc.stream.listen((state) {
      if (world.entities.containsKey(entity.id)) {
        onStateChange(entity, state);
      }
    });
  }

  /// The core logic method. This is called whenever a BLoC instance
  /// managed by this system emits a new state.
  void onStateChange(Entity entity, dynamic state);

  @override
  void onEntityRemoved(Entity entity) {
    if (_subscriptions.containsKey(entity.id)) {
      _subscriptions.remove(entity.id)?.cancel();
    }
    super.onEntityRemoved(entity);
  }

  @override
  void onRemovedFromWorld() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.onRemovedFromWorld();
  }
}
