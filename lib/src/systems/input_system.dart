import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/input_events.dart';

/// A system that listens for input events sent from the UI thread and
/// triggers the corresponding logic in the background isolate.
class InputSystem extends System {
  StreamSubscription? _tapSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _tapSubscription = world.eventBus.on<EntityTapEvent>(_onTap);
  }

  @override
  void onRemovedFromWorld() {
    _tapSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onTap(EntityTapEvent event) {
    final entity = world.entities[event.id];
    if (entity == null) return;

    final clickable = entity.get<ClickableComponent>();
    clickable?.onTap(entity);
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
