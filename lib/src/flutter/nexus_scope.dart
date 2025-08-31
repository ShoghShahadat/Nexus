import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/flutter/component_cache.dart';

/// یک ویجت ریشه که چرخه حیات دنیای Nexus را مدیریت کرده و آن را
/// از طریق BuildContext در دسترس تمام ویجت‌های فرزند قرار می‌دهد.
/// این ویجت جایگزین NexusWidget شده و همانند Provider عمل می‌کند.
class NexusScope extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final Future<void> Function()? isolateInitializer;
  final Widget child;

  const NexusScope({
    super.key,
    required this.worldProvider,
    required this.child,
    this.isolateInitializer,
  });

  /// نزدیک‌ترین NexusManager را در درخت ویجت پیدا می‌کند.
  static NexusManager of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_NexusScopeInherited>();
    assert(scope != null, 'No NexusScope found in context');
    return scope!.manager;
  }

  /// نزدیک‌ترین ComponentCache را در درخت ویجت پیدا می‌کند.
  static ComponentCache cacheOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_NexusScopeInherited>();
    assert(scope != null, 'No NexusScope found in context');
    return scope!.cache;
  }

  @override
  State<NexusScope> createState() => _NexusScopeState();
}

class _NexusScopeState extends State<NexusScope> {
  static NexusManager? _staticDebugManager;

  late final NexusManager _manager;
  late final ComponentCache _cache;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _initializeManager();

    _cache = ComponentCache(manager: _manager);

    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleStateChanged,
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    // در زمان Hot Reload، درخواست یک همگام‌سازی کامل می‌کنیم
    _manager.hydrate();
  }

  void _initializeManager() {
    final useIsolate = !kIsWeb;

    if (kDebugMode && useIsolate) {
      _staticDebugManager ??= NexusIsolateManager();
      _manager = _staticDebugManager!;
    } else {
      _manager =
          useIsolate ? NexusIsolateManager() : NexusSingleThreadManager();
    }
    _manager.spawn(
      widget.worldProvider,
      isolateInitializer: widget.isolateInitializer,
      rootIsolateToken: RootIsolateToken.instance,
    );
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

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _cache.dispose();
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
    return _NexusScopeInherited(
      manager: _manager,
      cache: _cache,
      child: widget.child,
    );
  }
}

/// یک InheritedWidget برای فراهم کردن دسترسی به Manager و Cache.
class _NexusScopeInherited extends InheritedWidget {
  final NexusManager manager;
  final ComponentCache cache;

  const _NexusScopeInherited({
    required this.manager,
    required this.cache,
    required super.child,
  });

  @override
  bool updateShouldNotify(_NexusScopeInherited oldWidget) {
    return manager != oldWidget.manager || cache != oldWidget.cache;
  }
}
