import 'dart:async';
import 'dart:isolate';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/render_packet.dart';
import 'package:nexus/src/events/input_events.dart';

/// A class that manages the background isolate where the NexusWorld runs.
/// It handles spawning, communication, and termination of the logic thread.
class NexusIsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  /// Spawns a new isolate to run the NexusWorld.
  ///
  /// [worldProvider] creates the NexusWorld instance.
  /// [isolateInitializer] is an optional function that runs inside the new
  /// isolate for setup, perfect for registering custom components.
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    void Function()? isolateInitializer,
  }) async {
    if (_isolate != null) return;

    final completer = Completer<SendPort>();

    _receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is List<RenderPacket>) {
        _renderPacketController.add(message);
      }
    });

    // FIX: Pass the initializer function to the isolate entry point.
    final entryPointArgs = [
      _receivePort.sendPort,
      isolateInitializer,
      worldProvider
    ];

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      entryPointArgs,
      debugName: 'NexusLogicIsolate',
    );
    _sendPort = await completer.future;
    // We no longer send the worldProvider here; it's part of the initial args.
  }

  /// Sends a command or event to the background isolate.
  void send(dynamic message) {
    _sendPort?.send(message);
  }

  /// Terminates the background isolate.
  void dispose() {
    _sendPort?.send('shutdown');
    _receivePort.close();
    _renderPacketController.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

/// The entry point for the background isolate.
void _isolateEntryPoint(List<dynamic> args) async {
  // FIX: Unpack arguments
  final mainSendPort = args[0] as SendPort;
  final isolateInitializer = args[1] as void Function()?;
  final worldProvider = args[2] as NexusWorld Function();

  // FIX: Run initializers for both core and custom components.
  registerCoreComponents();
  isolateInitializer?.call();

  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  NexusWorld? world;
  Timer? timer;
  final stopwatch = Stopwatch();

  // The world is now created right away.
  world = worldProvider();
  stopwatch.start();

  timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
    final dt =
        stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    stopwatch.reset();

    world!.update(dt);

    final packets = <RenderPacket>[];
    for (final entity in world.entities.values) {
      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          serializableComponents[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }

      if (serializableComponents.isNotEmpty) {
        packets.add(
            RenderPacket(id: entity.id, components: serializableComponents));
      }
    }

    final removedEntityIds = world.getAndClearRemovedEntities();
    for (final id in removedEntityIds) {
      packets.add(RenderPacket(id: id, components: {}, isRemoved: true));
    }

    if (packets.isNotEmpty) {
      mainSendPort.send(packets);
    }
  });

  isolateReceivePort.listen((message) {
    if (message is EntityTapEvent) {
      world?.eventBus.fire(message);
    } else if (message is NexusPointerMoveEvent) {
      world?.eventBus.fire(message);
    } else if (message == 'shutdown') {
      timer?.cancel();
      isolateReceivePort.close();
    }
  });
}
