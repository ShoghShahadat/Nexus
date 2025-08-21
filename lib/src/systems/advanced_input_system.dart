import 'package:nexus/nexus.dart';

/// A system that processes keyboard events and updates the state of the
/// focused entity.
///
/// --- FIX v1.4.3 ---
/// This system now processes events in sync with the main game loop (`update`)
/// instead of asynchronously. It queues incoming key events and processes them
/// once per frame. This ensures a consistent input state for other systems
/// and prevents stuttering caused by OS-level key repeat delays.
class AdvancedInputSystem extends System {
  // A queue to hold key events received from the UI thread since the last frame.
  final List<NexusKeyEvent> _keyEventsQueue = [];

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for events and add them to the queue.
    world.eventBus.on<NexusKeyEvent>((event) {
      _keyEventsQueue.add(event);
    });
  }

  @override
  bool matches(Entity entity) {
    // This system runs on the focused entity every frame to process the queue.
    return entity.has<InputFocusComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final currentKeyboardState =
        entity.get<KeyboardInputComponent>() ?? KeyboardInputComponent();
    final newKeysDown = Set<int>.from(currentKeyboardState.keysDown);
    String? lastChar;

    // Process all events that have arrived since the last frame.
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
      // If no new events, clear the character from the last frame.
      lastChar = null;
    }

    // Always add/update the component to ensure the state is consistent every frame.
    // This solves the movement stuttering issue.
    entity.add(KeyboardInputComponent(
      keysDown: newKeysDown,
      lastCharacter: lastChar,
    ));
  }
}
