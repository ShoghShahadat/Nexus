import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
  final Future<void> Function()? isolateInitializer;

  const NexusWidget({
    super.key,
    required this.worldProvider,
    required this.renderingSystem,
    this.isolateInitializer,
  });

  @override
  State<NexusWidget> createState() => _NexusWidgetState();
}

class _NexusWidgetState extends State<NexusWidget> {
  // A static manager to survive hot reloads in debug mode.
  static NexusManager? _staticDebugManager;

  late NexusManager _manager;
  late final AppLifecycleListener _lifecycleListener;
  final FocusNode _focusNode = FocusNode();
  StreamSubscription? _renderPacketSubscription;

  @override
  void initState() {
    super.initState();
    _initializeManager();

    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleStateChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // This is the key to fixing hot reload!
    // We re-subscribe to the (preserved) manager's stream and
    // explicitly request a full state snapshot.
    _subscribeToRenderPackets();
    _manager.hydrate();
  }

  void _onLifecycleStateChanged(AppLifecycleState state) {
    final status = switch (state) {
      AppLifecycleState.resumed => AppLifecycleStatus.resumed,
      AppLifecycleState.inactive => AppLifecycleStatus.inactive,
      AppLifecycleState.paused => AppLifecycleStatus.paused,
      AppLifecycleState.detached => AppLifecycleStatus.detached,
      AppLifecycleState.hidden => AppLifecycleStatus.hidden,
    };
    _manager.send(AppLifecycleEvent(status));
  }

  void _handleKeyEvent(KeyEvent event) {
    _manager.send(NexusKeyEvent(
      logicalKeyId: event.logicalKey.keyId,
      character: event.character,
      isKeyDown: event is KeyDownEvent || event is KeyRepeatEvent,
    ));
  }

  void _initializeManager() {
    final useIsolate = !kIsWeb;

    if (kDebugMode && useIsolate) {
      if (_staticDebugManager == null) {
        _staticDebugManager = NexusIsolateManager();
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _spawnWorld();
      } else {
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        // Do not re-spawn, just re-hydrate in reassemble.
      }
    } else {
      _manager =
          useIsolate ? NexusIsolateManager() : NexusSingleThreadManager();
      widget.renderingSystem.setManager(_manager);
      _spawnWorld();
    }
  }

  void _spawnWorld() {
    _manager.spawn(
      widget.worldProvider,
      isolateInitializer: widget.isolateInitializer,
      // Required for using platform channels in the isolate.
      rootIsolateToken: RootIsolateToken.instance,
    );
    _subscribeToRenderPackets();
  }

  void _subscribeToRenderPackets() {
    _renderPacketSubscription?.cancel();
    _renderPacketSubscription = _manager.renderPacketStream
        .listen(widget.renderingSystem.updateFromPackets);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _focusNode.dispose();
    _renderPacketSubscription?.cancel();

    // Dispose the manager only in release builds or on the web.
    // In debug mode, the static manager is preserved across hot reloads.
    if (!kDebugMode || kIsWeb) {
      _manager.dispose();
      if (kDebugMode) {
        _staticDebugManager = null;
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget's primary job is to provide context (Layout, Input)
    // and delegate the actual rendering to the rendering system.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rootEntityId =
            widget.renderingSystem.getAllIdsWithTag('root').firstOrNull;

        if (rootEntityId != null) {
          final currentInfo =
              widget.renderingSystem.get<ScreenInfoComponent>(rootEntityId);
          final newWidth = constraints.maxWidth;
          final newHeight = constraints.maxHeight;

          if (currentInfo == null ||
              currentInfo.width != newWidth ||
              currentInfo.height != newHeight) {
            _manager.send(ScreenResizedEvent(
              newWidth: newWidth,
              newHeight: newHeight,
              newOrientation: newWidth > newHeight
                  ? ScreenOrientation.landscape
                  : ScreenOrientation.portrait,
            ));
          }
        }

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          // AnimatedBuilder ensures that the rendering system's own build
          // method is called whenever new entities are added or removed.
          child: AnimatedBuilder(
            animation: widget.renderingSystem,
            builder: (context, child) => widget.renderingSystem.build(context),
          ),
        );
      },
    );
  }
}
