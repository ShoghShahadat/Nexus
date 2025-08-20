import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
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
      worldProvider,
      rootIsolateToken,
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
  final isolateInitializer = args[1] as Future<void> Function()?;
  final worldProvider = args[2] as NexusWorld Function();
  final rootIsolateToken = args[3] as RootIsolateToken?;

  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  try {
    if (rootIsolateToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    }

    if (isolateInitializer != null) {
      await isolateInitializer();
    }

    registerCoreComponents();

    final world = worldProvider();

    await world.init();

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
          final component = entity.getByType(componentType);
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

      for (final entity in world.entities.values) {
        entity.clearDirty();
      }
    });

    isolateReceivePort.listen((message) {
      if (message is SaveDataEvent) {
        world.eventBus.fire(message);
      } else if (message is EntityTapEvent) {
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
  } catch (e, stacktrace) {
    debugPrint('[Isolate] FATAL ERROR during initialization: $e');
    debugPrint(stacktrace.toString());
  }
}
