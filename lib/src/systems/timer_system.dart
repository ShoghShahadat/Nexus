import 'package:nexus/nexus.dart';

/// A system that processes entities with a `TimerComponent` to manage
/// scheduled and recurring tasks.
class TimerSystem extends System {
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
      hasChanged = true;
    }

    // *** FINAL FIX: Make the system more predictable and robust. ***
    // Instead of aggressively removing the component when the task list is empty,
    // we will always re-add it if its internal state (the tasks list) has changed.
    // This prevents race conditions where another system tries to access the component
    // right after it has been removed. The component's lifecycle should be managed
    // by the system that created it (e.g., ButtonInteractionSystem) or a GarbageCollector.
    if (hasChanged) {
      entity.add(timerComponent);
    }
  }
}
