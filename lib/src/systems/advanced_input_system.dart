import 'package:nexus/nexus.dart';

/// A system that processes keyboard events and updates the state of the
/// focused entity.
///
/// --- RE-ARCHITECTED as an UpdateSystem ---
/// It needs to run every frame to process the event queue.
class AdvancedInputSystem extends UpdateSystem {
  final List<NexusKeyEvent> _keyEventsQueue = [];

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<NexusKeyEvent>((event) {
      _keyEventsQueue.add(event);
    });
  }

  @override
  bool matches(Entity entity) {
    return entity.has<InputFocusComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // Only process if there are new events
    if (_keyEventsQueue.isEmpty) return;

    final currentKeyboardState =
        entity.get<KeyboardInputComponent>() ?? KeyboardInputComponent();
    final newKeysDown = Set<int>.from(currentKeyboardState.keysDown);
    String? lastChar;

    for (final event in _keyEventsQueue) {
      if (event.isKeyDown) {
        newKeysDown.add(event.logicalKeyId);
        lastChar = event.character;
      } else {
        newKeysDown.remove(event.logicalKeyId);
      }
    }

    entity.add(KeyboardInputComponent(
      keysDown: newKeysDown,
      lastCharacter: lastChar ?? currentKeyboardState.lastCharacter,
    ));

    // Clear the queue after processing
    _keyEventsQueue.clear();
  }
}
