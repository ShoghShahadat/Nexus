import 'dart:async';
import 'package:bloc/bloc.dart';
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
      _subscription = _bloc.stream.listen(onStateChange);
    } on StateError catch (e) {
      // It's good practice to keep a log for fatal errors.
      print(
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
    _subscription?.cancel();
    super.onRemovedFromWorld();
  }
}
