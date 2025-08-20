import 'dart:async';
import 'dart:ui';
import 'package:nexus/nexus.dart';

/// An abstract interface for managing the NexusWorld lifecycle and communication.
abstract class NexusManager {
  Stream<List<RenderPacket>> get renderPacketStream;

  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
  });

  void send(dynamic message);

  /// --- NEW: Added isHotReload parameter for guaranteed state saving ---
  Future<void> dispose({bool isHotReload = false});
}
