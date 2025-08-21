import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';

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
  // *** FIX: Use a static manager in debug mode to preserve state across Hot Reloads. ***
  // Static variables are not re-initialized on hot reload, allowing the NexusWorld
  // and all its state to survive the process seamlessly.
  static NexusManager? _staticDebugManager;

  late NexusManager _manager;
  late final AppLifecycleListener _lifecycleListener;
  final FocusNode _focusNode = FocusNode();

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

  void _onLifecycleStateChanged(AppLifecycleState state) {
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

  void _handleKeyEvent(KeyEvent event) {
    final nexusEvent = NexusKeyEvent(
      logicalKeyId: event.logicalKey.keyId,
      character: event.character,
      isKeyDown: event is KeyDownEvent || event is KeyRepeatEvent,
    );
    _manager.send(nexusEvent);
  }

  void _initializeManager() {
    // --- MODIFIED: Hot Reload aware initialization ---
    if (kDebugMode) {
      // In debug mode, we reuse the static manager if it exists.
      if (_staticDebugManager == null) {
        _staticDebugManager = NexusSingleThreadManager();
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _spawnWorld(); // Spawn only when the manager is first created.
      } else {
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        // The world already exists, just re-establish the stream listener.
        _manager.renderPacketStream
            .listen(widget.renderingSystem.updateFromPackets);
      }
    } else {
      // Release mode behavior is unchanged (uses isolates on non-web).
      if (!kIsWeb) {
        _manager = NexusIsolateManager();
      } else {
        _manager = NexusSingleThreadManager();
      }
      widget.renderingSystem.setManager(_manager);
      _spawnWorld();
    }
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

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _focusNode.dispose();
    // --- MODIFIED: In debug mode, we DO NOT dispose the static manager. ---
    // It lives for the entire application run to preserve state.
    if (!kDebugMode) {
      _manager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _manager.send(ScreenResizedEvent(
          newWidth: constraints.maxWidth,
          newHeight: constraints.maxHeight,
          newOrientation: constraints.maxWidth > constraints.maxHeight
              ? ScreenOrientation.landscape
              : ScreenOrientation.portrait,
        ));

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Listener(
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
          ),
        );
      },
    );
  }
}
