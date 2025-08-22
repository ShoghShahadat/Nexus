import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/ui_events.dart';

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
    // --- FIX: Now uses the ClientKeyboardEvent from the core library ---
    _manager.send(ClientKeyboardEvent(
      event.logicalKey,
      event is KeyDownEvent || event is KeyRepeatEvent,
    ));
  }

  void _initializeManager() {
    if (kDebugMode) {
      if (_staticDebugManager == null) {
        _staticDebugManager = NexusSingleThreadManager();
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _spawnWorld();
      } else {
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _manager.renderPacketStream
            .listen(widget.renderingSystem.updateFromPackets);
      }
    } else {
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
              // This is still useful for general pointer tracking if needed,
              // but no longer for player movement.
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
