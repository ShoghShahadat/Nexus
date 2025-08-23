// ==============================================================================
// File: lib/systems/network_system.dart
// Author: Your Intelligent Assistant
// Version: 4.0
// Description: Manages client-side connection and state synchronization.
// Changes:
// - REFACTORED: Now populates a NetworkSyncComponent instead of directly
//   modifying PositionComponent and VelocityComponent to support interpolation.
// - ADDED: Creates an initial PositionComponent for new entities.
// ==============================================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import '../components/interpolation_component.dart';
import '../components/network_components.dart';
import '../events.dart';
import '../network/i_web_socket_client.dart';

class NetworkSystem extends System {
  final String serverUrl;
  final BinaryWorldSerializer _serializer;
  late final IWebSocketClient _webSocketClient;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionStateSubscription;

  final Map<int, EntityId> _serverEntityMap = {};
  final Stopwatch _stopwatch = Stopwatch();

  NetworkSystem(this._serializer, {required this.serverUrl});

  @override
  Future<void> init() async {
    super.init();
    _stopwatch.start();
    _webSocketClient = services.get<IWebSocketClient>();
    _messageSubscription = _webSocketClient.onMessage.listen(_onData);
    _connectionStateSubscription = _webSocketClient.onConnectionStateChange
        .listen(_onConnectionStateChanged);
    await _webSocketClient.connect(serverUrl);
  }

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<SendDirectionalInputEvent>(_onSendInput);
  }

  void _onConnectionStateChanged(bool isConnected) {
    if (isConnected) {
      _updateStatus('Connected!', isConnected: true);
    } else {
      _updateStatus('Connecting to $serverUrl...', isConnected: false);
      for (final clientEntityId in _serverEntityMap.values) {
        world.removeEntity(clientEntityId);
      }
      _serverEntityMap.clear();
      world.rootEntity.get<BlackboardComponent>()?.remove('local_player_id');
    }
  }

  void _onData(Uint8List data) {
    final reader = BinaryReader(data);
    final double timestamp = _stopwatch.elapsedMicroseconds / 1000000.0;

    final updatedCount = reader.readInt32();
    for (int i = 0; i < updatedCount; i++) {
      final serverId = reader.readInt32();
      final componentCount = reader.readInt32();
      final otherComponents = <Component>[];
      PositionComponent? posFromServer;
      VelocityComponent? velFromServer;

      for (int j = 0; j < componentCount; j++) {
        final typeId = reader.readInt32();
        final component = _serializer.factoryRegistry.create(typeId);
        if (component is BinaryComponent) {
          component.fromBinary(reader);
          if (component is PositionComponent) {
            posFromServer = component;
          } else if (component is VelocityComponent) {
            velFromServer = component;
          } else {
            otherComponents.add(component);
          }
        }
      }

      if (posFromServer != null) {
        final syncComponent = NetworkSyncComponent(
          targetX: posFromServer.x,
          targetY: posFromServer.y,
          velocityX: velFromServer?.x ?? 0.0,
          velocityY: velFromServer?.y ?? 0.0,
          timestamp: timestamp,
        );
        otherComponents.add(syncComponent);
      }

      if (_serverEntityMap.containsKey(serverId)) {
        final clientEntityId = _serverEntityMap[serverId]!;
        final clientEntity = world.entities[clientEntityId];
        clientEntity?.addComponents(otherComponents);
      } else {
        final newEntity = Entity();
        newEntity.add(LifecyclePolicyComponent(isPersistent: true));
        if (posFromServer != null) {
          newEntity.add(PositionComponent(
              x: posFromServer.x,
              y: posFromServer.y,
              width: posFromServer.width,
              height: posFromServer.height));
        }
        newEntity.addComponents(otherComponents);
        world.addEntity(newEntity);
        _serverEntityMap[serverId] = newEntity.id;
      }
    }

    final deletedCount = reader.readInt32();
    for (int i = 0; i < deletedCount; i++) {
      final serverId = reader.readInt32();
      if (_serverEntityMap.containsKey(serverId)) {
        final clientEntityId = _serverEntityMap.remove(serverId)!;
        world.removeEntity(clientEntityId);
      }
    }

    _updateLocalPlayerReference();
  }

  void _updateLocalPlayerReference() {
    Entity? localPlayerEntity;
    for (final entityId in _serverEntityMap.values) {
      final entity = world.entities[entityId];
      final playerComp = entity?.get<PlayerComponent>();
      if (playerComp != null && playerComp.isLocalPlayer) {
        localPlayerEntity = entity;
        break;
      }
    }

    if (localPlayerEntity != null) {
      world.rootEntity
          .get<BlackboardComponent>()
          ?.set('local_player_id', localPlayerEntity.id);
      final playerComp = localPlayerEntity.get<PlayerComponent>()!;
      playerComp.isLocalPlayer = false;
      localPlayerEntity.add(playerComp);
    }
  }

  void _onSendInput(SendDirectionalInputEvent event) {
    final writer = BinaryWriter();
    writer.writeInt32(1);
    writer.writeDouble(event.dx);
    writer.writeDouble(event.dy);
    _webSocketClient.send(writer.toBytes());
  }

  void _updateStatus(String message, {bool isConnected = false}) {
    world.rootEntity.add(NetworkStateComponent(
        isConnected: isConnected, statusMessage: message));
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}

  @override
  void onRemovedFromWorld() {
    _messageSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _webSocketClient.disconnect();
    _serverEntityMap.clear();
    _stopwatch.stop();
    super.onRemovedFromWorld();
  }
}
