// ==============================================================================
// File: lib/systems/network_system.dart
// Author: Your Intelligent Assistant
// Version: 9.0
// Description: Manages client-side connection and state synchronization.
// Changes:
// - CRITICAL FIX: Now correctly passes the updated width and height from the
//   server into the NetworkSyncComponent and ReconciliationComponent.
// ==============================================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import '../components/interpolation_component.dart';
import '../components/network_components.dart';
import '../components/reconciliation_component.dart';
import '../events.dart';
import '../network/i_web_socket_client.dart';

class NetworkSystem extends System {
  final String serverUrl;
  final BinaryWorldSerializer _serializer;
  late final IWebSocketClient _webSocketClient;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionStateSubscription;

  final Map<int, EntityId> _serverEntityMap = {};
  EntityId? _localPlayerId;

  NetworkSystem(this._serializer, {required this.serverUrl});

  @override
  Future<void> init() async {
    super.init();
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
      _localPlayerId = null;
      world.rootEntity.get<BlackboardComponent>()?.set('local_player_id', null);
    }
  }

  void _onData(Uint8List data) {
    final reader = BinaryReader(data);

    final updatedCount = reader.readInt32();
    for (int i = 0; i < updatedCount; i++) {
      final serverId = reader.readInt32();
      final componentCount = reader.readInt32();
      final components = <Component>[];
      PositionComponent? posFromServer;

      for (int j = 0; j < componentCount; j++) {
        final typeId = reader.readInt32();
        final component = _serializer.factoryRegistry.create(typeId);
        if (component is BinaryComponent) {
          component.fromBinary(reader);
          if (component is PositionComponent) {
            posFromServer = component;
          } else {
            components.add(component);
          }
        }
      }

      final clientEntityId = _serverEntityMap[serverId];
      Entity? clientEntity;

      if (clientEntityId != null) {
        clientEntity = world.entities[clientEntityId];
      } else {
        clientEntity = Entity();
        clientEntity.add(LifecyclePolicyComponent(isPersistent: true));
        if (posFromServer != null) {
          clientEntity.add(PositionComponent(
              x: posFromServer.x,
              y: posFromServer.y,
              width: posFromServer.width,
              height: posFromServer.height));
        }
        world.addEntity(clientEntity);
        _serverEntityMap[serverId] = clientEntity.id;
      }

      if (clientEntity == null) continue;

      // --- CRITICAL FIX: Update local PositionComponent and Sync Components ---
      if (posFromServer != null) {
        // Always update the entity's own PositionComponent with the new size.
        final localPos = clientEntity.get<PositionComponent>();
        if (localPos != null) {
          localPos.width = posFromServer.width;
          localPos.height = posFromServer.height;
          clientEntity.add(localPos);
        }

        if (clientEntity.id == _localPlayerId) {
          // For our player, send state to the Reconciliation system.
          clientEntity.add(ReconciliationComponent(
            serverX: posFromServer.x,
            serverY: posFromServer.y,
          ));
        } else {
          // For others, send state to the Interpolation system.
          clientEntity.add(NetworkSyncComponent(
            targetX: posFromServer.x,
            targetY: posFromServer.y,
            targetWidth: posFromServer.width,
            targetHeight: posFromServer.height,
          ));
        }
      }

      clientEntity.addComponents(components);
    }

    final deletedCount = reader.readInt32();
    for (int i = 0; i < deletedCount; i++) {
      final serverId = reader.readInt32();
      if (_serverEntityMap.containsKey(serverId)) {
        final clientEntityId = _serverEntityMap.remove(serverId)!;
        if (clientEntityId == _localPlayerId) _localPlayerId = null;
        world.removeEntity(clientEntityId);
      }
    }

    _updateLocalPlayerReference();
  }

  void _updateLocalPlayerReference() {
    if (_localPlayerId != null) return;

    for (final entityId in _serverEntityMap.values) {
      final entity = world.entities[entityId];
      final playerComp = entity?.get<PlayerComponent>();
      if (playerComp != null && playerComp.isLocalPlayer) {
        _localPlayerId = entity!.id;
        world.rootEntity
            .get<BlackboardComponent>()
            ?.set('local_player_id', _localPlayerId);
        entity.add(ControlledPlayerComponent());
        playerComp.isLocalPlayer = false;
        entity.add(playerComp);
        break;
      }
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
    super.onRemovedFromWorld();
  }
}
