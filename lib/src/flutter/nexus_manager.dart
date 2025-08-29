import 'dart:async';
import 'dart:ui';
import 'package:nexus/nexus.dart';

/// An abstract interface for managing the NexusWorld lifecycle and communication.
abstract class NexusManager {
  Stream<List<RenderPacket>> get renderPacketStream;

  /// Provides access to the world instance, primarily for debug/single-thread mode.
  /// Returns null if the world is in a separate isolate.
  NexusWorld? get world;

  /// Spawns the world, either in a new isolate or on the main thread.
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
  });

  /// Sends a generic message or event to the logic world.
  void send(dynamic message);

  /// *** NEW: Triggers a full state synchronization from the logic world to the UI. ***
  /// This is essential for re-syncing the UI after a hot reload.
  void hydrate();

  /// Disposes of the manager and its resources.
  /// The [isHotReload] flag is used in debug mode to prevent destroying
  /// the underlying world/isolate.
  Future<void> dispose({bool isHotReload = false});
}
