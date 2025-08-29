import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexus/nexus.dart';

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
  NexusWorld? get world => null;

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
  void hydrate() {
    _sendPort?.send('hydrate');
  }

  @override
  Future<void> dispose({bool isHotReload = false}) async {
    if (isHotReload) {
      // debugPrint((
      // "[NexusIsolateManager] Hot reload detected. Isolate will be preserved.");
      return;
    }

    // debugPrint(("[NexusIsolateManager] Disposing isolate...");
    _sendPort?.send('shutdown');
    _receivePort.close();
    await _renderPacketController.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

// --- Isolate Entry Point ---

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

    // *** FINAL FIX: Proactive Hydration ***
    // Immediately send the initial state of the world to the UI after initialization.
    // This solves the initial loading screen bug by ensuring the UI gets data
    // as soon as the logic isolate is ready, without waiting for a message from the UI.
    // debugPrint((
    // "[NexusLogicIsolate] World initialized. Sending initial hydration packet.");
    final initialPackets = <RenderPacket>[];
    for (final entity in world.entities.values) {
      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          serializableComponents[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      if (serializableComponents.isNotEmpty) {
        initialPackets.add(
            RenderPacket(id: entity.id, components: serializableComponents));
      }
    }
    if (initialPackets.isNotEmpty) {
      mainSendPort.send(initialPackets);
    }
    // End of Proactive Hydration block

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
      if (message is String) {
        switch (message) {
          case 'shutdown':
            timer.cancel();
            world.clear();
            isolateReceivePort.close();
            break;
          case 'hydrate':
            // debugPrint((
            // "[NexusLogicIsolate] Hydration requested. Sending full world snapshot.");
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
                packets.add(RenderPacket(
                    id: entity.id, components: serializableComponents));
              }
            }
            if (packets.isNotEmpty) {
              mainSendPort.send(packets);
            }
            break;
        }
      } else {
        world.eventBus.fire(message);
      }
    });
  } catch (e, stacktrace) {
    debugPrint('[NexusLogicIsolate] FATAL ERROR: $e');
    debugPrint(stacktrace.toString());
  }
}
