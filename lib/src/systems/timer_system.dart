import 'package:nexus/nexus.dart';

/// A system that processes entities with a `TimerComponent` to manage
/// scheduled and recurring tasks.
/// سیستمی که موجودیت‌های دارای `TimerComponent` را برای مدیریت وظایف
/// زمان‌بندی شده و تکراری پردازش می‌کند.
class TimerSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.has<TimerComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final timerComponent = entity.get<TimerComponent>()!;
    // Create a copy for safe iteration, as tasks might be removed.
    // یک کپی برای پیمایش امن ایجاد می‌کنیم، زیرا ممکن است وظایف حذف شوند.
    final tasksToRemove = <TimerTask>{};

    for (final task in timerComponent.tasks) {
      task.elapsedTime += dt;

      // Fire the onTick event every frame if it exists.
      // رویداد onTick را در هر فریم، در صورت وجود، منتشر می‌کنیم.
      if (task.onTickEvent != null) {
        world.eventBus.fire(task.onTickEvent);
      }

      if (task.elapsedTime >= task.duration) {
        // Fire the completion event.
        // رویداد اتمام را منتشر می‌کنیم.
        world.eventBus.fire(task.onCompleteEvent);

        if (task.repeats) {
          // Reset for the next cycle.
          // برای چرخه بعدی ریست می‌کنیم.
          task.elapsedTime -= task.duration;
        } else {
          // Mark for removal if it's a one-shot timer.
          // اگر تایمر یک‌باره است، آن را برای حذف علامت‌گذاری می‌کنیم.
          tasksToRemove.add(task);
        }
      }
    }

    if (tasksToRemove.isNotEmpty) {
      // Remove completed tasks from the original list.
      // وظایف تکمیل‌شده را از لیست اصلی حذف می‌کنیم.
      timerComponent.tasks.removeWhere((task) => tasksToRemove.contains(task));
    }

    // If there are no more tasks, remove the component itself.
    // اگر وظیفه دیگری باقی نمانده، خود کامپوننت را حذف می‌کنیم.
    if (timerComponent.tasks.isEmpty) {
      entity.remove<TimerComponent>();
    } else {
      // Re-add the component to signal that its internal state has changed.
      // کامپوننت را دوباره اضافه می‌کنیم تا نشان دهیم وضعیت داخلی آن تغییر کرده است.
      entity.add(timerComponent);
    }
  }
}
