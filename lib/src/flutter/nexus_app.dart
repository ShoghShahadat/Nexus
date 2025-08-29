// File: packages/nexus/lib/src/flutter/nexus_app.dart

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/flutter/declarative_rendering_system.dart';

/// A top-level widget that bootstraps a Nexus application.
///
/// This widget handles the lifecycle of the core Nexus systems, including
/// the [DeclarativeRenderingSystem] and the [NexusManager], and crucially,
/// preserves their state across hot reloads for a seamless development experience.
class NexusApp extends StatefulWidget {
  /// A function that provides an instance of the [NexusWorld].
  final NexusWorld Function() worldProvider;

  /// The root of the UI, an [IWidgetBuilder] that defines the initial widget tree.
  final IWidgetBuilder rootBuilder;

  /// An optional theme for the material application.
  final ThemeData? theme;

  /// An optional function to run inside the isolate before the world is created.
  final Future<void> Function()? isolateInitializer;

  const NexusApp({
    super.key,
    required this.worldProvider,
    required this.rootBuilder,
    this.isolateInitializer,
    this.theme,
  });

  @override
  State<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends State<NexusApp> {
  late final DeclarativeRenderingSystem renderingSystem;

  @override
  void initState() {
    super.initState();
    // The rendering system is created once and preserved for the entire
    // lifecycle of the app, surviving hot reloads.
    renderingSystem = DeclarativeRenderingSystem(
      rootBuilder: widget.rootBuilder,
      rootEntityTag: 'root', // 'root' is a sensible default convention.
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: widget.theme ?? ThemeData.light(),
      home: NexusWidget(
        worldProvider: widget.worldProvider,
        renderingSystem: renderingSystem,
        isolateInitializer: widget.isolateInitializer,
      ),
    );
  }
}
