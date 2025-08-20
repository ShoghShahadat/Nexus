import 'dart:async';
import 'dart:isolate';
import 'package:nexus/nexus.dart';

/// Manages the background isolate where the NexusWorld runs.
class NexusIsolateManager implements NexusManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  @override
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  @override
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
  }

  @override
  void send(dynamic message) {
    _sendPort?.send(message);
  }

  @override
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
  final mainSendPort = args[0] as SendPort;
  final isolateInitializer = args[1] as void Function()?;
  final worldProvider = args[2] as NexusWorld Function();

  registerCoreComponents();
  isolateInitializer?.call();

  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  final world = worldProvider();
  final stopwatch = Stopwatch()..start();

  final timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
    final dt =
        stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    stopwatch.reset();

    world.update(dt);

    final packets = <RenderPacket>[];
    for (final entity in world.entities.values) {
      if (entity.dirtyComponents.isEmpty) continue;

      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final componentType in entity.dirtyComponents) {
        // --- FIX: Use the new getByType method ---
        final component = entity.getByType(componentType);
        // --- END FIX ---
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
      world.eventBus.fire(message);
    } else if (message is NexusPointerMoveEvent) {
      world.eventBus.fire(message);
    } else if (message is UndoEvent) {
      world.eventBus.fire(message);
    } else if (message is RedoEvent) {
      world.eventBus.fire(message);
    } else if (message == 'shutdown') {
      timer.cancel();
      world.clear();
      isolateReceivePort.close();
    }
  });
}
