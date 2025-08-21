import 'dart:async';

/// A simple event bus for decoupled communication between different parts
/// of the application, particularly between different modules.
///
/// Systems can listen for specific event types and react to them, or
/// they can fire events to signal that something has happened.
class EventBus {
  final StreamController _streamController;

  /// If true, the stream controller broadcasts its events to multiple listeners.
  bool isBroadcast;

  // --- FIX: Added a flag to prevent events from being added to a closed controller ---
  bool _isClosed = false;

  /// Creates an event bus.
  ///
  /// If [sync] is true, events are passed directly to listeners.
  /// If [isBroadcast] is true, multiple listeners can subscribe to the stream.
  EventBus({bool sync = false, this.isBroadcast = true})
      : _streamController = StreamController.broadcast(sync: sync);

  /// Listens for events of a specific type [T].
  ///
  /// The [onData] callback is called when an event of type [T] is fired.
  /// Note: Listening for `dynamic` is an advanced use-case, typically for
  /// dispatcher systems like RuleSystem that need to react to any event.
  StreamSubscription<T> on<T>(void Function(T event) onData) {
    return _streamController.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(onData);
  }

  /// Fires a new event on the bus.
  ///
  /// All listeners for the type of the [event] object will be notified.
  void fire(dynamic event) {
    // --- FIX: Guard against firing events on a closed bus ---
    if (_isClosed) {
      return;
    }
    _streamController.add(event);
  }

  /// Destroys the event bus and releases all resources.
  void destroy() {
    // --- FIX: Mark the bus as closed before actually closing the stream ---
    _isClosed = true;
    _streamController.close();
  }
}
