import 'dart:async';
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/component_update.dart';
import 'package:nexus/src/core/render_packet.dart';

class NexusSingleThreadManager implements NexusManager {
  NexusWorld? _world;
  @override
  NexusWorld? get world => _world;

  Ticker? _ticker;
  final _stopwatch = Stopwatch();

  final _updateController = StreamController<ComponentUpdate>.broadcast();
  @override
  Stream<ComponentUpdate> get componentUpdateStream => _updateController.stream;

  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  @override
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  @override
  void hydrate() {
    if (_world == null) return;
    final List<RenderPacket> packets = [];
    for (final entity in _world!.entities.values) {
      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          final json = (component as SerializableComponent).toJson();
          serializableComponents[component.runtimeType.toString()] = json;
          _updateController.add(ComponentUpdate(
            entityId: entity.id,
            componentTypeName: component.runtimeType.toString(),
            componentJson: json,
          ));
        }
      }
      if (serializableComponents.isNotEmpty) {
        packets.add(
            RenderPacket(id: entity.id, components: serializableComponents));
      }
    }
    if (packets.isNotEmpty) {
      _renderPacketController.add(packets);
    }
  }

  void _updateLoop(Duration elapsed) {
    if (_world == null) return;
    final dt =
        _stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _stopwatch.reset();
    _stopwatch.start();
    _world!.update(dt);

    final List<RenderPacket> dirtyPackets = [];
    for (final entity in _world!.entities.values) {
      if (entity.dirtyComponents.isEmpty) continue;
      final dirtyComponentJson = <String, Map<String, dynamic>>{};
      for (final componentType in entity.dirtyComponents) {
        final component = entity.getByType(componentType);
        if (component is SerializableComponent) {
          final json = (component as SerializableComponent).toJson();
          dirtyComponentJson[component.runtimeType.toString()] = json;
          _updateController.add(ComponentUpdate(
            entityId: entity.id,
            componentTypeName: component.runtimeType.toString(),
            componentJson: json,
          ));
        }
      }
      if (dirtyComponentJson.isNotEmpty) {
        dirtyPackets
            .add(RenderPacket(id: entity.id, components: dirtyComponentJson));
      }
      entity.clearDirty();
    }
    if (dirtyPackets.isNotEmpty) {
      _renderPacketController.add(dirtyPackets);
    }

    final removedEntityIds = _world!.getAndClearRemovedEntities();
    if (removedEntityIds.isNotEmpty) {
      final List<RenderPacket> removalPackets = [];
      for (final id in removedEntityIds) {
        removalPackets
            .add(RenderPacket(id: id, components: {}, isRemoved: true));
        _updateController.add(ComponentUpdate(
            entityId: id, componentTypeName: 'Entity', isRemoved: true));
      }
      _renderPacketController.add(removalPackets);
    }
  }

  @override
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
  }) async {
    if (_world != null) return;
    if (isolateInitializer != null) {
      await isolateInitializer();
    }
    registerCoreComponents();
    _world = worldProvider();
    await _world!.init();
    hydrate();
    _stopwatch.start();
    _ticker = Ticker(_updateLoop);
    _ticker!.start();
  }

  @override
  void send(dynamic message) {
    _world?.eventBus.fire(message);
  }

  @override
  Future<void> dispose({bool isHotReload = false}) async {
    if (isHotReload) {
      _world?.eventBus.fire(SaveDataEvent());
      _updateLoop(Duration.zero);
      return;
    }
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _world?.clear();
    _world = null;
    await _updateController.close();
    await _renderPacketController.close();
  }
}
