import 'dart:async';
import 'package:nexus/nexus.dart';

/// A system that processes keyboard events and updates the state of the
/// focused entity.
class AdvancedInputSystem extends System {
  final List<NexusKeyEvent> _keyEventsQueue = [];
  StreamSubscription? _keyEventSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Store the subscription to be able to cancel it later.
    _keyEventSubscription = world.eventBus.on<NexusKeyEvent>((event) {
      _keyEventsQueue.add(event);
    });
  }

  @override
  void onRemovedFromWorld() {
    // Cancel the subscription when the system is removed.
    _keyEventSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  @override
  bool matches(Entity entity) {
    return entity.has<InputFocusComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final currentKeyboardState =
        entity.get<KeyboardInputComponent>() ?? KeyboardInputComponent();
    final newKeysDown = Set<int>.from(currentKeyboardState.keysDown);
    String? lastChar;

    if (_keyEventsQueue.isNotEmpty) {
      for (final event in _keyEventsQueue) {
        if (event.isKeyDown) {
          newKeysDown.add(event.logicalKeyId);
          lastChar = event.character;
        } else {
          newKeysDown.remove(event.logicalKeyId);
        }
      }
      _keyEventsQueue.clear();
    } else {
      lastChar = null;
    }

    entity.add(KeyboardInputComponent(
      keysDown: newKeysDown,
      lastCharacter: lastChar,
    ));
  }
}
