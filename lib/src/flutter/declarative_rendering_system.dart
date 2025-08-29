import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// The ultimate, generic rendering system for Nexus.
///
/// This class is completely unopinionated about the UI structure. It acts as
/// the root of the render tree and delegates the entire build process to a
/// single `rootBuilder` provided during configuration.
///
/// This empowers developers to build any UI imaginable by composing different
/// `IWidgetBuilder`s, from a simple Centered Text to a complex Scaffold,
/// without ever needing to extend or create a new RenderingSystem.
class DeclarativeRenderingSystem extends FlutterRenderingSystem {
  /// The single entry point for building the entire widget tree.
  final IWidgetBuilder rootBuilder;

  /// The tag used to find the root entity, which often holds global state
  /// like theme or directionality. Defaults to 'root'.
  final String rootEntityTag;

  DeclarativeRenderingSystem({
    required this.rootBuilder,
    this.rootEntityTag = 'root',
  }) : super();

  @override
  Widget build(BuildContext context) {
    if (manager == null || getAllIdsWithTag(rootEntityTag).isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rootEntityId = getAllIdsWithTag(rootEntityTag).first;

    // The entire build process is delegated to the provided root builder.
    // This system's only job is to find the root entity and kick things off.
    return rootBuilder.build(context, this, rootEntityId);
  }
}
