import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart'; // برای استفاده از debugPrint
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/render_packet.dart';
import 'package:nexus/src/events/input_events.dart';

/// A class that manages the background isolate where the NexusWorld runs.
/// It handles spawning, communication, and termination of the logic thread.
class NexusIsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  // A dedicated broadcast stream controller for render packets.
  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  /// Spawns a new isolate to run the NexusWorld.
  Future<void> spawn(NexusWorld Function() worldProvider) async {
    if (_isolate != null) return;

    final completer = Completer<SendPort>();

    // The single listener for the ReceivePort.
    _receivePort.listen((message) {
      if (message is SendPort) {
        // First message is always the SendPort from the isolate.
        completer.complete(message);
      } else if (message is List<RenderPacket>) {
        debugPrint(
            '[NexusIsolateManager] Main thread received ${message.length} packets from isolate via ReceivePort. Adding to stream.'); // <--- افزودن این لاگ جدید
        _renderPacketController.add(message);
      }
    });

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort.sendPort,
      debugName: 'NexusLogicIsolate',
    );
    debugPrint('[NexusIsolateManager] Isolate spawned.');

    _sendPort = await completer.future;
    debugPrint(
        '[NexusIsolateManager] SendPort received from isolate. Sending worldProvider.');
    // Send the world provider to the isolate to start the world.
    _sendPort!.send(worldProvider);
  }

  /// Sends a command or event to the background isolate.
  void send(dynamic message) {
    _sendPort?.send(message);
  }

  /// Terminates the background isolate.
  void dispose() {
    debugPrint('[NexusIsolateManager] Disposing isolate manager.');
    _sendPort?.send('shutdown');
    _receivePort.close();
    _renderPacketController.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

/// The entry point for the background isolate.
void _isolateEntryPoint(SendPort mainSendPort) async {
  registerCoreComponents();
  debugPrint('[Isolate] Core components registered in the new isolate.');

  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  NexusWorld? world;
  Timer? timer;
  final stopwatch = Stopwatch();

  isolateReceivePort.listen((message) {
    if (message is NexusWorld Function()) {
      world = message();
      debugPrint('[Isolate] World provided and initialized.');
      stopwatch.start();
      debugPrint('[Isolate] Stopwatch started.');

      timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        final dt =
            stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
        stopwatch.reset();

        world!.update(dt);
        debugPrint('[Isolate] World updated with dt: $dt');

        final packets = <RenderPacket>[];
        for (final entity in world!.entities.values) {
          final serializableComponents = <String, Map<String, dynamic>>{};
          for (final component in entity.allComponents) {
            if (component is SerializableComponent) {
              serializableComponents[component.runtimeType.toString()] =
                  (component as SerializableComponent).toJson();
            }
          }

          if (serializableComponents.isNotEmpty) {
            packets.add(RenderPacket(
                id: entity.id, components: serializableComponents));
          }
        }
        if (packets.isNotEmpty) {
          mainSendPort.send(packets);
          debugPrint(
              '[Isolate] Sent ${packets.length} render packets to main.');
        } else {
          debugPrint('[Isolate] No serializable components to send.');
        }
      });
    } else if (message is EntityTapEvent) {
      debugPrint('[Isolate] Received EntityTapEvent for ID: ${message.id}');
      world?.eventBus.fire(message);
    } else if (message == 'shutdown') {
      debugPrint(
          '[Isolate] Shutdown message received. Cancelling timer and closing port.');
      timer?.cancel();
      isolateReceivePort.close();
    }
  });
}
