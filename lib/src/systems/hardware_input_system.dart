import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/hardware_input_events.dart';

/// A system that processes raw hardware button events and translates them into
/// higher-level, domain-specific events for the application to consume.
class HardwareInputSystem extends System {
  StreamSubscription? _hardwareEventSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _hardwareEventSubscription =
        world.eventBus.on<HardwareButtonEvent>(_onHardwareEvent);
  }

  @override
  void onRemovedFromWorld() {
    _hardwareEventSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onHardwareEvent(HardwareButtonEvent event) {
    switch (event.type) {
      case HardwareButtonType.back:
        print('[HardwareInputSystem] Back button pressed.');
        break;
      case HardwareButtonType.volumeUp:
        print('[HardwareInputSystem] Volume Up pressed.');
        break;
      case HardwareButtonType.volumeDown:
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
