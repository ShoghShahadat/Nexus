import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:nexus/nexus.dart';

/// Manages the NexusWorld lifecycle on the main UI thread for web compatibility.
class NexusSingleThreadManager implements NexusManager {
  NexusWorld? _world;
  Ticker? _ticker;
  final _stopwatch = Stopwatch();

  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  @override
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  @override
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    void Function()? isolateInitializer,
  }) async {
    // On the web, the "isolate" initializer runs directly.
    isolateInitializer?.call();

    _world = worldProvider();
    _stopwatch.start();

    // Use a Ticker for smoother animations, synchronized with Flutter's rendering pipeline.
    _ticker = Ticker((_) {
      if (_world == null) return;

      final dt =
          _stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      _stopwatch.reset();

      _world!.update(dt);

      final packets = <RenderPacket>[];
      for (final entity in _world!.entities.values) {
        if (entity.dirtyComponents.isEmpty) continue;

        final serializableComponents = <String, Map<String, dynamic>>{};
        for (final componentType in entity.dirtyComponents) {
          // --- FIX: Use the new getByType method ---
          final component = entity.getByType(componentType);
          // --- END FIX ---
          if (component is SerializableComponent) {
            serializableComponents[component.runtimeType.toString()] =
                (component as SerializableComponent).toJson();
          }
        }
        if (serializableComponents.isNotEmpty) {
          packets.add(
              RenderPacket(id: entity.id, components: serializableComponents));
        }
      }

      final removedEntityIds = _world!.getAndClearRemovedEntities();
      for (final id in removedEntityIds) {
        packets.add(RenderPacket(id: id, components: {}, isRemoved: true));
      }

      if (packets.isNotEmpty) {
        _renderPacketController.add(packets);
      }
    });

    _ticker!.start();
  }

  @override
  void send(dynamic message) {
    // Events are fired directly since we are on the same thread.
    _world?.eventBus.fire(message);
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _world?.clear();
    _world = null;
    _renderPacketController.close();
  }
}
