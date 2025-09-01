import 'dart:async';
import 'dart:math';
import 'package:nexus/nexus.dart';

/// A mock implementation of the WebSocket service that simulates a live
/// data stream for the user activity chart.
class MockWebSocketService implements IWebSocketService {
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, Timer> _timers = {};
  final _random = Random();

  @override
  Stream connect(String connectionId, String url,
      {Iterable<String>? protocols}) {
    // If a connection for this ID already exists, return its stream.
    if (_controllers.containsKey(connectionId)) {
      return _controllers[connectionId]!.stream;
    }

    // Create a new stream controller for this connection.
    final controller = StreamController<dynamic>.broadcast();
    _controllers[connectionId] = controller;

    // Simulate connection latency.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_controllers.containsKey(connectionId)) return;

      controller.add({'status': 'connected'});

      // Start a timer to periodically send new random data.
      _timers[connectionId] =
          Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        final data = List.generate(
            7, (index) => _random.nextInt(100) + 20 * (index / 7));
        controller.add({'data': data});
      });
    });

    return controller.stream;
  }

  @override
  void disconnect(String connectionId) {
    _timers[connectionId]?.cancel();
    _controllers[connectionId]?.close();
    _timers.remove(connectionId);
    _controllers.remove(connectionId);
  }

  @override
  void disconnectAll() {
    for (var id in _timers.keys) {
      _timers[id]?.cancel();
    }
    for (var id in _controllers.keys) {
      _controllers[id]?.close();
    }
    _timers.clear();
    _controllers.clear();
  }

  @override
  void send(String connectionId, data) {
    // Not implemented for this mock service.
  }
}
