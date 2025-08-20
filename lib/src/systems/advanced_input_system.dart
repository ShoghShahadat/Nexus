import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/input_focus_component.dart';
import 'package:nexus/src/components/keyboard_input_component.dart';
import 'package:nexus/src/events/input_events.dart';

/// A system that processes keyboard events and updates the state of the
/// focused entity.
/// سیستمی که رویدادهای کیبورد را پردازش کرده و وضعیت موجودیت متمرکز را به‌روز می‌کند.
class AdvancedInputSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<NexusKeyEvent>(_onKeyEvent);
  }

  void _onKeyEvent(NexusKeyEvent event) {
    // Find the entity that currently has input focus.
    // موجودیتی که در حال حاضر فوکوس ورودی را دارد، پیدا می‌کند.
    final focusedEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<InputFocusComponent>());

    if (focusedEntity == null) return;

    // Get the current keyboard state or create a new one.
    // وضعیت فعلی کیبورد را دریافت کرده یا یک وضعیت جدید ایجاد می‌کند.
    final currentKeyboardState =
        focusedEntity.get<KeyboardInputComponent>() ?? KeyboardInputComponent();

    final newKeysDown = Set<int>.from(currentKeyboardState.keysDown);
    String? newCharacter;

    if (event.isKeyDown) {
      newKeysDown.add(event.logicalKeyId);
      newCharacter = event.character;
    } else {
      newKeysDown.remove(event.logicalKeyId);
      newCharacter = null;
    }

    // Add the updated component to the entity.
    // کامپوننت به‌روز شده را به موجودیت اضافه می‌کند.
    focusedEntity.add(KeyboardInputComponent(
      keysDown: newKeysDown,
      lastCharacter: newCharacter,
    ));
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {
    // Logic is in the event listener.
  }
}
