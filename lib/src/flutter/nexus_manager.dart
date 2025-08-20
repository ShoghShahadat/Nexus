import 'dart:async';
import 'package:nexus/nexus.dart';

// *** NEW FILE ***
// This abstract class defines a common interface for both the Isolate-based
// and single-threaded managers. This allows NexusWidget to remain agnostic
// about the execution model.

/// An abstract interface for managing the NexusWorld lifecycle and communication.
abstract class NexusManager {
  /// A stream that emits render packets from the logic thread to the UI thread.
  Stream<List<RenderPacket>> get renderPacketStream;

  /// Initializes and starts the NexusWorld.
  ///
  /// [worldProvider] is a function that creates the NexusWorld instance.
  /// [isolateInitializer] is an optional function for setup code that needs to
  /// run in the same context as the world (e.g., registering components).
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    void Function()? isolateInitializer,
  });

  /// Sends a message or event from the UI to the NexusWorld.
  void send(dynamic message);

  /// Shuts down the NexusWorld and releases all resources.
  void dispose();
}
