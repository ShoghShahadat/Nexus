import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/app_lifecycle_event.dart';

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
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _initializeManager();

    // Setup the lifecycle listener to bridge events to the logic isolate.
    // شنونده چرخه حیات را برای ارسال رویدادها به isolate منطق تنظیم می‌کنیم.
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleStateChanged,
    );
  }

  void _onLifecycleStateChanged(AppLifecycleState state) {
    // Map Flutter's state to our custom, isolate-safe enum.
    // وضعیت فلاتر را به enum سفارشی و امن برای isolate خودمان مپ می‌کنیم.
    final AppLifecycleStatus status;
    switch (state) {
      case AppLifecycleState.resumed:
        status = AppLifecycleStatus.resumed;
        break;
      case AppLifecycleState.inactive:
        status = AppLifecycleStatus.inactive;
        break;
      case AppLifecycleState.paused:
        status = AppLifecycleStatus.paused;
        break;
      case AppLifecycleState.detached:
        status = AppLifecycleStatus.detached;
        break;
      case AppLifecycleState.hidden:
        status = AppLifecycleStatus.hidden;
        break;
    }
    _manager.send(AppLifecycleEvent(status));
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
      _manager = NexusIsolateManager();
    } else {
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

  void _resetManager() async {
    print("--- Hot Reload Detected: Beginning stateful reset ---");

    await _manager.dispose(isHotReload: true);

    StorageAdapter? preservedStorage;
    if (GetIt.I.isRegistered<StorageAdapter>()) {
      preservedStorage = GetIt.I.get<StorageAdapter>();
    }
    GetIt.I.reset(dispose: false);
    if (preservedStorage != null) {
      GetIt.I.registerSingleton<StorageAdapter>(preservedStorage);
    }

    _initializeManager();
    print("--- Stateful reset complete ---");
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        final pointerEvent = NexusPointerMoveEvent(
            event.localPosition.dx, event.localPosition.dy);
        _manager.send(pointerEvent);
        if (kDebugMode) {
          _manager.send(SaveDataEvent());
        }
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
