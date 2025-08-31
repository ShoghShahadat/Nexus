import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';
import 'package:nexus/src/core/render_packet.dart';

class NexusIsolateManager implements NexusManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  final _updateController = StreamController<ComponentUpdate>.broadcast();
  @override
  Stream<ComponentUpdate> get componentUpdateStream => _updateController.stream;

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
      } else if (message is ComponentUpdate) {
        _updateController.add(message);
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
      return;
    }
    _sendPort?.send('shutdown');
    _receivePort.close();
    await _updateController.close();
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

    void sendHydrationData() {
      // Send legacy RenderPackets
      final List<RenderPacket> packets = [];
      for (final entity in world.entities.values) {
        final serializableComponents = <String, Map<String, dynamic>>{};
        for (final component in entity.allComponents) {
          if (component is SerializableComponent) {
            serializableComponents[component.runtimeType.toString()] =
                (component as SerializableComponent).toJson();

            // Send granular ESCUEM ComponentUpdate
            mainSendPort.send(ComponentUpdate(
              entityId: entity.id,
              componentTypeName: component.runtimeType.toString(),
              componentJson: (component as SerializableComponent).toJson(),
            ));
          }
        }
        if (serializableComponents.isNotEmpty) {
          packets.add(
              RenderPacket(id: entity.id, components: serializableComponents));
        }
      }
      if (packets.isNotEmpty) {
        mainSendPort.send(packets);
      }
    }

    sendHydrationData();

    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final dt =
          stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      stopwatch.reset();
      stopwatch.start();
      world.update(dt);

      final List<RenderPacket> dirtyPackets = [];
      for (final entity in world.entities.values) {
        if (entity.dirtyComponents.isEmpty) continue;

        final Map<String, Map<String, dynamic>> dirtyComponentJson = {};
        for (final componentType in entity.dirtyComponents) {
          final component = entity.getByType(componentType);
          if (component is SerializableComponent) {
            final json = (component as SerializableComponent).toJson();
            dirtyComponentJson[component.runtimeType.toString()] = json;

            // Send granular ESCUEM ComponentUpdate
            mainSendPort.send(ComponentUpdate(
              entityId: entity.id,
              componentTypeName: component.runtimeType.toString(),
              componentJson: json,
            ));
          }
        }
        if (dirtyComponentJson.isNotEmpty) {
          dirtyPackets
              .add(RenderPacket(id: entity.id, components: dirtyComponentJson));
        }
        entity.clearDirty();
      }

      if (dirtyPackets.isNotEmpty) {
        mainSendPort.send(dirtyPackets);
      }

      final removedEntityIds = world.getAndClearRemovedEntities();
      if (removedEntityIds.isNotEmpty) {
        final List<RenderPacket> removalPackets = [];
        for (final id in removedEntityIds) {
          // Send legacy removal packet
          removalPackets
              .add(RenderPacket(id: id, components: {}, isRemoved: true));
          // Send ESCUEM removal update
          mainSendPort.send(ComponentUpdate(
              entityId: id, componentTypeName: 'Entity', isRemoved: true));
        }
        mainSendPort.send(removalPackets);
      }
    });

    isolateReceivePort.listen((message) {
      if (message is String) {
        if (message == 'shutdown') {
          world.clear();
          isolateReceivePort.close();
        } else if (message == 'hydrate') {
          sendHydrationData();
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
