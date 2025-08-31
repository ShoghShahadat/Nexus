import 'package:nexus/nexus.dart';

/// A system that processes entities with a `TimerComponent` to manage
/// scheduled and recurring tasks.
///
/// --- RE-ARCHITECTED as an UpdateSystem ---
class TimerSystem extends UpdateSystem {
  @override
  bool matches(Entity entity) {
    return entity.has<TimerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final timerComponent = entity.get<TimerComponent>()!;
    final tasksToRemove = <TimerTask>{};
    bool hasChanged = false;

    for (final task in timerComponent.tasks) {
      task.elapsedTime += dt;
      hasChanged = true; // elapsedTime always changes

      if (task.onTickEvent != null) {
        world.eventBus.fire(task.onTickEvent);
      }

      if (task.elapsedTime >= task.duration) {
        if (task.onCompleteEvent != null) {
          world.eventBus.fire(task.onCompleteEvent);
        }

        if (task.repeats) {
          task.elapsedTime -= task.duration;
        } else {
          tasksToRemove.add(task);
        }
      }
    }

    if (tasksToRemove.isNotEmpty) {
      timerComponent.tasks.removeWhere((task) => tasksToRemove.contains(task));
    }

    if (hasChanged) {
      // Re-add the component to save its updated state (elapsedTime, removed tasks).
      entity.add(timerComponent);
    }
  }
}
