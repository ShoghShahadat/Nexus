import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';

/// A generic system that listens to state changes from a specific BLoC/Cubit
/// registered in the service locator.
abstract class BlocSystem<B extends BlocBase<S>, S> extends System {
  StreamSubscription? _subscription;
  late final B _bloc;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    try {
      _bloc = services.get<B>();
      debugPrint('[BlocSystem][${B.toString()}] Subscribing to stream...');
      _subscription = _bloc.stream.listen(onStateChange);

      // --- FIX: Removed immediate processing of initial state ---
      // The initial state should be set manually on the entity during creation.
      // This system will now only react to *new* state changes after initialization.
      // onStateChange(_bloc.state); // This line caused the race condition.
      debugPrint(
          '[BlocSystem][${B.toString()}] Subscription successful. Ready for new states.');
    } on StateError catch (e) {
      debugPrint(
          '[BlocSystem] FATAL ERROR: Could not get ${B.toString()} from GetIt. Make sure it is registered. Details: $e');
      rethrow;
    }
  }

  /// The core logic method, called for every new state from the BLoC.
  void onStateChange(S state);

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}

  @override
  void onRemovedFromWorld() {
    debugPrint('[BlocSystem][${B.toString()}] Disposing stream subscription.');
    _subscription?.cancel();
    super.onRemovedFromWorld();
  }
}
