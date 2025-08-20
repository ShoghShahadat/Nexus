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
        debugPrint('[NexusIsolateManager][UI] Received SendPort from Isolate.');
        completer.complete(message);
      } else if (message is List<RenderPacket>) {
        // --- LOGGING ADDED ---
        debugPrint(
            '[NexusIsolateManager][UI] Received ${message.length} render packets from Isolate.');
        _renderPacketController.add(message);
      } else {
        debugPrint(
            '[NexusIsolateManager][UI] Received unknown message: $message');
      }
    });

    final entryPointArgs = [
      _receivePort.sendPort,
      isolateInitializer,
      worldProvider,
      rootIsolateToken,
    ];

    debugPrint('[NexusIsolateManager][UI] Spawning NexusLogicIsolate...');
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      entryPointArgs,
      debugName: 'NexusLogicIsolate',
    );
    _sendPort = await completer.future;
    debugPrint(
        '[NexusIsolateManager][UI] Isolate spawn complete. Manager is ready.');
  }

  @override
  void send(dynamic message) {
    debugPrint(
        '[NexusIsolateManager][UI] Sending message to Isolate: ${message.runtimeType}');
    _sendPort?.send(message);
  }

  @override
  void dispose() {
    debugPrint(
        '[NexusIsolateManager][UI] Disposing manager and killing Isolate.');
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
      debugPrint('[NexusLogicIsolate] Running isolate initializer...');
      await isolateInitializer();
      debugPrint('[NexusLogicIsolate] Isolate initializer complete.');
    }

    registerCoreComponents();

    debugPrint('[NexusLogicIsolate] Creating NexusWorld...');
    final world = worldProvider();
    debugPrint(
        '[NexusLogicIsolate] NexusWorld created. Initializing systems...');
    await world.init();
    debugPrint(
        '[NexusLogicIsolate] Systems initialized. Starting update loop.');

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
        // --- LOGGING ADDED ---
        debugPrint(
            '[NexusLogicIsolate] Sending ${packets.length} render packets to UI.');
        for (var packet in packets) {
          debugPrint(
              '  - Packet for Entity ID: ${packet.id}, Components: ${packet.components.keys.toList()}');
        }
        mainSendPort.send(packets);
      }

      for (final entity in world.entities.values) {
        entity.clearDirty();
      }
    });

    isolateReceivePort.listen((message) {
      debugPrint(
          '[NexusLogicIsolate] Received message from UI: ${message.runtimeType}');
      if (message is SaveDataEvent ||
          message is EntityTapEvent ||
          message is NexusPointerMoveEvent ||
          message is UndoEvent ||
          message is RedoEvent) {
        world.eventBus.fire(message);
      } else if (message == 'shutdown') {
        debugPrint(
            '[NexusLogicIsolate] Shutdown signal received. Cleaning up.');
        timer.cancel();
        world.clear();
        isolateReceivePort.close();
      }
    });
  } catch (e, stacktrace) {
    debugPrint('[NexusLogicIsolate] FATAL ERROR: $e');
    debugPrint(stacktrace.toString());
  }
}
