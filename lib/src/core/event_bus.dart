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

  /// Creates an event bus.
  ///
  /// If [sync] is true, events are passed directly to listeners.
  /// If [isBroadcast] is true, multiple listeners can subscribe to the stream.
  EventBus({bool sync = false, this.isBroadcast = true})
      : _streamController = StreamController.broadcast(sync: sync);

  /// Listens for events of a specific type [T].
  ///
  /// The [onData] callback is called when an event of type [T] is fired.
  StreamSubscription<T> on<T>(void Function(T event) onData) {
    if (T == dynamic) {
      throw ArgumentError(
          'Listening for dynamic events is not supported. Please provide a specific event type.');
    }
    return _streamController.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(onData);
  }

  /// Fires a new event on the bus.
  ///
  /// All listeners for the type of the [event] object will be notified.
  void fire(dynamic event) {
    _streamController.add(event);
  }

  /// Destroys the event bus and releases all resources.
  void destroy() {
    _streamController.close();
  }
}
