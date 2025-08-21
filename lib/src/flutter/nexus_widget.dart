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

  // --- FIX: didUpdateWidget is no longer needed for Hot Reload management ---
  // The Key mechanism handles this reliably.
  /*
  @override
  void didUpdateWidget(NexusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode) {
      _resetManager();
    }
  }
  */

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

  // --- FIX: The complex and error-prone reset logic is completely removed. ---
  /*
  void _resetManager() async {
    // ... (removed)
  }
  */

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _focusNode.dispose();
    _manager.dispose();
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
