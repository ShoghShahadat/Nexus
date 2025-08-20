import 'dart:async';
import 'dart:ui';
import 'package:nexus/nexus.dart';

/// An abstract interface for managing the NexusWorld lifecycle and communication.
abstract class NexusManager {
  /// A stream that emits render packets from the logic thread to the UI thread.
  Stream<List<RenderPacket>> get renderPacketStream;

  /// Initializes and starts the NexusWorld.
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
  });

  /// Sends a message or event from the UI to the NexusWorld.
  void send(dynamic message);

  /// Shuts down the NexusWorld and releases all resources.
  Future<void> dispose();
}
