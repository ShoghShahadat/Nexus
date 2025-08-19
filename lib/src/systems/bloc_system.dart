import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nexus/src/components/bloc_component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/system.dart';

/// A generic system that listens to state changes from a specific
/// type of `BlocComponent`.
///
/// By making the system itself generic, we ensure type safety and eliminate
/// runtime type errors with generics.
abstract class BlocSystem<B extends BlocBase<S>, S> extends System {
  final Map<EntityId, StreamSubscription> _subscriptions = {};

  /// Overridden to specifically target entities that have the exact
  /// generic `BlocComponent` this system is interested in.
  @override
  bool matches(Entity entity) {
    return entity.has<BlocComponent<B, S>>();
  }

  /// This method is now only called for entities that are guaranteed to have
  /// the correct `BlocComponent`.
  @override
  void update(Entity entity, double dt) {
    if (_subscriptions.containsKey(entity.id)) return;

    final blocComponent = entity.get<BlocComponent<B, S>>()!;

    // 1. Immediately process the BLoC's current state.
    onStateChange(entity, blocComponent.bloc.state);

    // 2. Subscribe to all future state changes.
    _subscriptions[entity.id] = blocComponent.bloc.stream.listen((state) {
      if (world.entities.containsKey(entity.id)) {
        onStateChange(entity, state);
      }
    });
  }

  /// The core logic method. It receives the correctly typed state.
  void onStateChange(Entity entity, S state);

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
