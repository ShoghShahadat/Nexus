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
    isolateInitializer?.call();
    _world = worldProvider();
    _stopwatch.start();

    _ticker = Ticker((_) {
      if (_world == null) return;

      final dt =
          _stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      _stopwatch.reset();

      // 1. Run logic, marking components as dirty.
      _world!.update(dt);

      // 2. Create packets from dirty components.
      final packets = <RenderPacket>[];
      for (final entity in _world!.entities.values) {
        final isFirstFrame = entity.dirtyComponents.isNotEmpty &&
            !_world!.entities.values.any((e) => e.dirtyComponents.isEmpty);

        if (entity.dirtyComponents.isEmpty && !isFirstFrame) continue;

        final componentsToSend = isFirstFrame
            ? entity.allComponents
            : entity.dirtyComponents
                .map((type) => entity.getByType(type))
                .whereType<Component>();

        final serializableComponents = <String, Map<String, dynamic>>{};
        for (final component in componentsToSend) {
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

      // 3. Send packets.
      if (packets.isNotEmpty) {
        _renderPacketController.add(packets);
      }

      // --- FIX: 4. Clear dirty flags AFTER creating packets. ---
      for (final entity in _world!.entities.values) {
        entity.clearDirty();
      }
    });

    _ticker!.start();
  }

  @override
  void send(dynamic message) {
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
