import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/hardware_input_events.dart';

/// A system that processes raw hardware button events and translates them into
/// higher-level, domain-specific events for the application to consume.
/// سیستمی که رویدادهای خام دکمه‌های سخت‌افزاری را پردازش کرده و آن‌ها را به
/// رویدادهای سطح بالاتر و مخصوص دامنه برنامه ترجمه می‌کند.
class HardwareInputSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<HardwareButtonEvent>(_onHardwareEvent);
  }

  void _onHardwareEvent(HardwareButtonEvent event) {
    switch (event.type) {
      case HardwareButtonType.back:
        // In a real application, you might fire a more specific event like:
        // world.eventBus.fire(PopRouteEvent());
        // or
        // world.eventBus.fire(CloseMenuEvent());
        print('[HardwareInputSystem] Back button pressed.');
        break;
      case HardwareButtonType.volumeUp:
        // You could fire an event like:
        // world.eventBus.fire(AdjustVolumeEvent(isUp: true));
        print('[HardwareInputSystem] Volume Up pressed.');
        break;
      case HardwareButtonType.volumeDown:
        // You could fire an event like:
        // world.eventBus.fire(AdjustVolumeEvent(isUp: false));
        print('[HardwareInputSystem] Volume Down pressed.');
        break;
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {
    // Logic is in the event listener.
  }
}
