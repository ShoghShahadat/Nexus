import 'dart:async';
import 'dart:ui';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';
import 'package:nexus/src/core/render_packet.dart';

/// An abstract interface for managing the NexusWorld lifecycle and communication.
/// Now supports both rendering architectures simultaneously.
abstract class NexusManager {
  /// Stream for the new ESCUEM architecture (granular component updates).
  Stream<ComponentUpdate> get componentUpdateStream;

  /// Stream for the legacy architecture (full entity state packets).
  Stream<List<RenderPacket>> get renderPacketStream;

  NexusWorld? get world;

  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
  });

  void send(dynamic message);

  void hydrate();

  Future<void> dispose({bool isHotReload = false});
}
