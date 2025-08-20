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

    // 1. Run all game logic. This will mark components as dirty.
    world.update(dt);

    // 2. Create packets based on the dirty components.
    final packets = <RenderPacket>[];
    for (final entity in world.entities.values) {
      // On the very first frame, all components are dirty.
      // We send all serializable components.
      final isFirstFrame = entity.dirtyComponents.isNotEmpty &&
          !world.entities.values.any((e) => e.dirtyComponents.isEmpty);

      if (entity.dirtyComponents.isEmpty && !isFirstFrame) continue;

      final componentsToSend = isFirstFrame
          ? entity.allComponents
          : entity.dirtyComponents
              .map((type) => entity.getByType(type))
              .whereType<Component>();

      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final component in componentsToSend) {
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

    // 3. Send packets if there's anything to send.
    if (packets.isNotEmpty) {
      mainSendPort.send(packets);
    }

    // --- FIX: 4. Clear dirty flags AFTER packets have been created. ---
    for (final entity in world.entities.values) {
      entity.clearDirty();
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
