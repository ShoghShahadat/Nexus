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
    // debugPrint(("🔄 [NexusWidget] Reassembling (Hot Reload detected).");
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
    if (kDebugMode && !kIsWeb) {
      if (_staticDebugManager == null) {
        // debugPrint((
        // "🚀 [NexusWidget] First run in debug mode. Creating and preserving IsolateManager.");
        _staticDebugManager = NexusIsolateManager();
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _spawnWorld();
      } else {
        // debugPrint((
        // "🔄 [NexusWidget] Hot reload: Re-using existing IsolateManager.");
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
      }
    } else {
      // debugPrint((
      // "🚀 [NexusWidget] Production or Web build. Creating fresh manager.");
      _manager = kIsWeb ? NexusSingleThreadManager() : NexusIsolateManager();
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
    _subscribeToRenderPackets();
  }

  void _subscribeToRenderPackets() {
    _renderPacketSubscription?.cancel();
    // debugPrint(("🎧 [NexusWidget] Subscribing to render packet stream.");
    _renderPacketSubscription = _manager.renderPacketStream
        .listen(widget.renderingSystem.updateFromPackets);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _focusNode.dispose();
    _renderPacketSubscription?.cancel();

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
    // *** FINAL FIX: The NexusWidget is now simpler. ***
    // It no longer needs an AnimatedBuilder. Its main job is to host the rendering
    // system and provide layout/input context.
    // debugPrint(("🎨 [NexusWidget] Build triggered.");

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
            // // debugPrint((
            //     "  - 📏 Screen size changed or is new. Sending ScreenResizedEvent ($newWidth x $newHeight).");
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
          child: widget.renderingSystem.build(context),
        );
      },
    );
  }
}
