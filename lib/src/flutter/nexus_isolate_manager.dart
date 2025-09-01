import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';

class NexusIsolateManager implements NexusManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  final _updateController = StreamController<ComponentUpdate>.broadcast();
  @override
  Stream<ComponentUpdate> get componentUpdateStream => _updateController.stream;

  // Legacy Stream - Not used by ESCUEM but kept for potential backward compatibility
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
      }
      // Silently ignore legacy RenderPacket messages if not used
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
    debugPrint('🧠 [Isolate] Entry point started.');
    if (rootIsolateToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    }

    if (isolateInitializer != null) {
      await isolateInitializer();
    } else {
      // Fallback if no initializer is provided from the UI side
      debugPrint(
          '🧠 [Isolate] No initializer provided, registering core components...');
      registerCoreComponents();
    }

    debugPrint('🧠 [Isolate] NexusWorld created. Initializing...');
    final world = worldProvider();
    await world.init();
    debugPrint('🧠 [Isolate] NexusWorld initialized.');

    // This function is now the single source of truth for sending state
    void _updateAndSendState() {
      // --- Handle Dirty Entities (Add/Update) ---
      for (final entity in world.entities.values) {
        if (entity.dirtyComponents.isEmpty) continue;

        for (final componentType in entity.dirtyComponents) {
          final component = entity.getByType(componentType);

          if (component != null && component is SerializableComponent) {
            debugPrint(
                '📤 [Isolate] Sending update for Entity ${entity.id}: Component \'${component.runtimeType.toString()}\', isRemoved: false');

            // --- CRITICAL FIX: Use an explicit cast to tell the compiler the exact type. ---
            // This resolves the type promotion issue permanently.
            // --- اصلاح حیاتی: از یک تبدیل نوع صریح برای گفتن نوع دقیق به کامپایلر استفاده می‌کند. ---
            // این کار مشکل ارتقاء نوع را برای همیشه حل می‌کند.
            mainSendPort.send(ComponentUpdate(
              entityId: entity.id,
              componentTypeName: component.runtimeType.toString(),
              componentJson: (component as SerializableComponent).toJson(),
              isRemoved: false,
            ));
          }
        }
        entity.clearDirty();
      }

      // --- Handle Removed Entities ---
      final removedEntityIds = world.getAndClearRemovedEntities();
      if (removedEntityIds.isNotEmpty) {
        for (final id in removedEntityIds) {
          // Send a single, simple removal message per entity
          mainSendPort.send(ComponentUpdate(
              entityId: id,
              componentTypeName: 'Entity', // Special type for removal
              isRemoved: true));
        }
      }
    }

    // --- Main Update Loop ---
    final stopwatch = Stopwatch()..start();
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final dt =
          stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      stopwatch.reset();
      stopwatch.start();
      world.update(dt);
      _updateAndSendState();
    });

    // --- Event Listener ---
    isolateReceivePort.listen((message) {
      if (message is String) {
        if (message == 'shutdown') {
          world.clear();
          isolateReceivePort.close();
        } else if (message == 'hydrate') {
          debugPrint(
              '💧 [Isolate] Hydration requested. Marking all components as dirty...');
          // Mark all serializable components of all entities as dirty
          for (final entity in world.entities.values) {
            for (final component in entity.allComponents) {
              if (component is SerializableComponent) {
                entity.dirtyComponents.add(component.runtimeType);
              }
            }
          }
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
