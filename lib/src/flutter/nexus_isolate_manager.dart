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
    debugPrint("🧠 [Isolate] Entry point started.");
    if (rootIsolateToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    }

    if (isolateInitializer != null) {
      await isolateInitializer();
    }

    debugPrint("🧠 [Isolate] Registering core components...");
    registerCoreComponents();
    final world = worldProvider();
    debugPrint("🧠 [Isolate] NexusWorld created. Initializing...");
    await world.init();
    debugPrint("🧠 [Isolate] NexusWorld initialized.");

    void hydrateWorld() {
      debugPrint(
          "💧 [Isolate] Hydration requested. Marking all components as dirty...");
      for (final entity in world.entities.values) {
        entity.markAllComponentsAsDirty();
      }
    }

    hydrateWorld();

    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final dt =
          stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      stopwatch.reset();
      stopwatch.start();
      world.update(dt);

      for (final entity in world.entities.values) {
        if (entity.dirtyComponents.isEmpty) continue;

        for (final componentType in entity.dirtyComponents) {
          final component = entity.getByType(componentType);

          final update = ComponentUpdate(
            entityId: entity.id,
            componentTypeName: componentType.toString(),
            isRemoved: component == null,
            // --- CRITICAL FIX: Explicitly cast to SerializableComponent ---
            // This tells the compiler that inside this expression, component is guaranteed
            // to be of the correct type, thus allowing the call to toJson().
            // اصلاح حیاتی: به صراحت به SerializableComponent تبدیل می‌کنیم.
            // این به کامپایلر می‌گوید که در داخل این عبارت، کامپوننت قطعاً از نوع صحیح است
            // و اجازه فراخوانی toJson() را می‌دهد.
            componentJson:
                (component != null && component is SerializableComponent)
                    ? (component as SerializableComponent).toJson()
                    : null,
          );
          // --- PRO LOGGING ---
          debugPrint(
              "📤 [Isolate] Sending update for Entity ${update.entityId}: Component '${update.componentTypeName}', isRemoved: ${update.isRemoved}");
          mainSendPort.send(update);
        }
        entity.clearDirty();
      }

      final removedEntityIds = world.getAndClearRemovedEntities();
      if (removedEntityIds.isNotEmpty) {
        for (final id in removedEntityIds) {
          mainSendPort.send(ComponentUpdate(
              entityId: id, componentTypeName: 'Entity', isRemoved: true));
        }
      }
    });

    isolateReceivePort.listen((message) {
      if (message is String) {
        if (message == 'shutdown') {
          debugPrint("🛑 [Isolate] Shutdown command received.");
          world.clear();
          isolateReceivePort.close();
        } else if (message == 'hydrate') {
          hydrateWorld();
        }
      } else {
        world.eventBus.fire(message);
      }
    });
  } catch (e, stacktrace) {
    debugPrint('❌ [Isolate] FATAL ERROR: $e');
    debugPrint(stacktrace.toString());
  }
}
