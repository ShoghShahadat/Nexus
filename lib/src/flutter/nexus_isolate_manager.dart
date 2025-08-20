import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/render_packet.dart';

/// A class that manages the background isolate where the NexusWorld runs.
/// It handles spawning, communication, and termination of the logic thread.
class NexusIsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  Stream<List<RenderPacket>> get renderPacketStream =>
      _receivePort.where((event) => event is List<RenderPacket>).cast();

  /// Spawns a new isolate to run the NexusWorld.
  ///
  /// [worldProvider] is a function that creates and inits the NexusWorld.
  /// This function will be executed inside the new isolate.
  Future<void> spawn(NexusWorld Function() worldProvider) async {
    if (_isolate != null) return;

    // Listen for the SendPort from the isolate.
    final completer = Completer<SendPort>();
    _receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      }
    });

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort.sendPort,
      debugName: 'NexusLogicIsolate',
    );

    _sendPort = await completer.future;
    // Send the world provider to the isolate to start the world.
    _sendPort!.send(worldProvider);
  }

  /// Sends a command or event to the background isolate.
  void send(dynamic message) {
    _sendPort?.send(message);
  }

  /// Terminates the background isolate.
  void dispose() {
    _sendPort?.send('shutdown');
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

/// The entry point for the background isolate.
/// This function sets up the world and runs the main update loop.
void _isolateEntryPoint(SendPort mainSendPort) async {
  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  NexusWorld? world;
  Timer? timer;
  final stopwatch = Stopwatch();

  isolateReceivePort.listen((message) {
    if (message is NexusWorld Function()) {
      world = message();
      stopwatch.start();

      // Main logic loop using a periodic timer.
      timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        final dt =
            stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
        stopwatch.reset();

        world!.update(dt);

        // After updating, gather renderable data and send it to the UI thread.
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
        mainSendPort.send(packets);
      });
    } else if (message == 'shutdown') {
      timer?.cancel();
      isolateReceivePort.close();
    }
  });
}
