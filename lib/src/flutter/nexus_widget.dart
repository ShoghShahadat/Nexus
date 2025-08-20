import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';

/// A Flutter widget that hosts and runs a NexusWorld.
class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
  final Future<void> Function()? isolateInitializer;
  final RootIsolateToken? rootIsolateToken;

  const NexusWidget({
    super.key,
    required this.worldProvider,
    required this.renderingSystem,
    this.isolateInitializer,
    this.rootIsolateToken,
  });

  @override
  State<NexusWidget> createState() => _NexusWidgetState();
}

class _NexusWidgetState extends State<NexusWidget> {
  late NexusManager _manager;

  @override
  void initState() {
    super.initState();
    _initializeManager();
  }

  @override
  void didUpdateWidget(NexusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode) {
      _resetManager();
    }
  }

  void _initializeManager() {
    if (!kIsWeb && !kDebugMode) {
      print("--- Nexus running in RELEASE mode (Multi-Threaded Isolate) ---");
      _manager = NexusIsolateManager();
    } else {
      if (kDebugMode) {
        print(
            "--- Nexus running in DEBUG mode (Single-Threaded for Hot Reload) ---");
      }
      _manager = NexusSingleThreadManager();
    }

    widget.renderingSystem.setManager(_manager);
    _spawnWorld();
  }

  void _spawnWorld() {
    _manager.spawn(
      widget.worldProvider,
      isolateInitializer: widget.isolateInitializer,
      rootIsolateToken: widget.rootIsolateToken,
    );
    _manager.renderPacketStream
        .listen(widget.renderingSystem.updateFromPackets);
  }

  /// --- FINAL FIX: Implemented safe, stateful Hot Reload logic ---
  void _resetManager() async {
    print("--- Hot Reload Detected: Attempting stateful reset ---");

    _manager.send(SaveDataEvent());
    await Future.delayed(const Duration(milliseconds: 50));
    await _manager.dispose();

    // 1. Safely check if the StorageAdapter is registered before getting it.
    StorageAdapter? preservedStorage;
    if (GetIt.I.isRegistered<StorageAdapter>()) {
      preservedStorage = GetIt.I.get<StorageAdapter>();
    }

    // 2. Reset the service locator.
    GetIt.I.reset(dispose: false);

    // 3. If we successfully preserved the adapter, re-register it.
    if (preservedStorage != null) {
      GetIt.I.registerSingleton<StorageAdapter>(preservedStorage);
    }

    // 4. Re-initialize the manager with the new code.
    _initializeManager();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        final NexusPointerMoveEvent pointerEvent = NexusPointerMoveEvent(
            event.localPosition.dx, event.localPosition.dy);
        _manager.send(pointerEvent);
      },
      child: AnimatedBuilder(
        animation: widget.renderingSystem,
        builder: (context, child) {
          return widget.renderingSystem.build(context);
        },
      ),
    );
  }
}
