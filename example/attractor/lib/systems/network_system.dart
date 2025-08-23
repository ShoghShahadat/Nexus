import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:nexus/nexus.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../components/network_components.dart';
import '../components/network_id_component.dart';
import '../events.dart';

// Message Type IDs for our custom binary protocol
const int newEntityMessage = 1;
const int componentUpdateMessage = 2;

/// Manages client-side P2P communication using a relay server.
class NetworkSystem extends System {
  final String serverUrl;
  final BinaryWorldSerializer _serializer;
  IO.Socket? _socket;

  final Map<String, EntityId> _networkEntityMap =
      {}; // Map<NetworkID, LocalEntityId>

  NetworkSystem(this._serializer, {required this.serverUrl});

  @override
  Future<void> init() async {
    super.init();
    _connect();
  }

  void _connect() {
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });
    _socket!.onConnect((_) {
      debugPrint('[NetworkSystem] ✅ Connected to relay server.');
      _updateStatus('Connected!', isConnected: true);
    });
    _socket!.onDisconnect((_) {
      debugPrint('[NetworkSystem] ❌ Disconnected from relay server.');
      _updateStatus('Connecting...', isConnected: false);
    });

    _socket!.on('welcome', _handleWelcome);
    _socket!.on('player_joined', _handlePlayerJoined);
    _socket!.on('player_left', _handlePlayerLeft);
    _socket!.on('new_host', _handleNewHost);
    _socket!.on('message_relayed', _handleMessageRelayed);
    _socket!.connect();
  }

  // --- Server Event Handlers ---

  void _handleWelcome(dynamic data) {
    final sid = data['sid'] as String;
    final isHost = data['is_host'] as bool;
    final otherPlayers = (data['other_players'] as List).cast<String>();

    debugPrint(
        '[NetworkSystem] 🥳 WELCOME! My SID is $sid. I am ${isHost ? "the Host" : "a Client"}.');
    debugPrint('[NetworkSystem] Other players already in game: $otherPlayers');

    _createPlayerEntity(sid, isLocalPlayer: true, isHost: isHost);
    for (final otherSid in otherPlayers) {
      _createPlayerEntity(otherSid, isLocalPlayer: false, isHost: false);
    }
  }

  void _handlePlayerJoined(dynamic data) {
    final sid = data['sid'] as String;
    debugPrint('[NetworkSystem] 🙋 Player joined: $sid');
    if (!_networkEntityMap.containsKey(sid)) {
      _createPlayerEntity(sid, isLocalPlayer: false, isHost: false);
    }
  }

  void _handlePlayerLeft(dynamic data) {
    final sid = data['sid'] as String;
    debugPrint('[NetworkSystem] 🚶 Player left: $sid');
    final entityId = _networkEntityMap.remove(sid);
    if (entityId != null) world.removeEntity(entityId);
  }

  void _handleNewHost(dynamic data) {
    final newHostSid = data['sid'] as String;
    debugPrint('[NetworkSystem] 👑 New host is: $newHostSid');
    world.entities.values.forEach((e) {
      final playerComp = e.get<PlayerComponent>();
      if (playerComp != null) {
        final wasHost = playerComp.isHost;
        playerComp.isHost = playerComp.sessionId == newHostSid;
        if (playerComp.isHost != wasHost) {
          e.add(playerComp);
        }
      }
    });
  }

  void _handleMessageRelayed(dynamic data) {
    if (data is! Uint8List) {
      debugPrint(
          '[NetworkSystem] ⚠️ Received non-binary relayed message. Ignoring.');
      return;
    }
    debugPrint(
        '[NetworkSystem] 📬 Received relayed binary message of size: ${data.lengthInBytes} bytes.');
    final reader = BinaryReader(data);
    final messageType = reader.readInt32();

    if (messageType == newEntityMessage)
      _deserializeNewEntity(reader);
    else if (messageType == componentUpdateMessage)
      _deserializeComponentUpdate(reader);
  }

  // --- Deserialization Logic ---

  void _deserializeNewEntity(BinaryReader reader) {
    final networkId = reader.readString();
    if (_networkEntityMap.containsKey(networkId)) return;

    final componentCount = reader.readInt32();
    debugPrint(
        '[NetworkSystem] 🔽 Deserializing NEW entity. NetworkID: $networkId, Components: $componentCount');

    final newEntity = Entity();
    for (int i = 0; i < componentCount; i++) {
      final typeId = reader.readInt32();
      final component = _serializer.factoryRegistry.create(typeId);
      component.fromBinary(reader);
      newEntity.add(component as Component);
    }
    world.addEntity(newEntity);
    _networkEntityMap[networkId] = newEntity.id;
  }

  void _deserializeComponentUpdate(BinaryReader reader) {
    final networkId = reader.readString();
    final typeId = reader.readInt32();

    final localEntityId = _networkEntityMap[networkId];
    final entity = world.entities[localEntityId];
    if (entity == null) {
      debugPrint(
          '[NetworkSystem] ⚠️ Could not find local entity for network ID $networkId to update.');
      return;
    }

    final component = _serializer.factoryRegistry.create(typeId);
    component.fromBinary(reader);
    entity.add(component as Component);
    debugPrint(
        '[NetworkSystem] 🔄 Applied component update (TypeID: $typeId) to entity with NetworkID: $networkId');
  }

  // --- Serialization & Sending Logic ---

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<RelayNewEntityEvent>((event) {
      debugPrint(
          '[NetworkSystem] 🔼 Relaying NEW entity. NetworkID: ${event.networkId}');
      final writer = BinaryWriter();
      writer.writeInt32(newEntityMessage);
      writer.writeString(event.networkId);
      writer.writeInt32(event.components.length);
      for (final component in event.components) {
        writer.writeInt32(component.typeId);
        component.toBinary(writer);
      }
      _socket?.emit('relay_message', writer.toBytes());
    });

    listen<RelayComponentStateEvent>((event) {
      debugPrint(
          '[NetworkSystem] 🔼 Relaying component update. NetworkID: ${event.networkId}, TypeID: ${event.component.typeId}');
      final writer = BinaryWriter();
      writer.writeInt32(componentUpdateMessage);
      writer.writeString(event.networkId);
      writer.writeInt32(event.component.typeId);
      event.component.toBinary(writer);
      _socket?.emit('relay_message', writer.toBytes());
    });
  }

  // --- Helper Methods ---

  Entity _createPlayerEntity(String sid,
      {required bool isLocalPlayer, required bool isHost}) {
    final playerEntity = Entity();
    playerEntity.add(NetworkIdComponent(networkId: sid));
    playerEntity.add(PositionComponent(x: 400, y: 500, width: 20, height: 20));
    playerEntity.add(VelocityComponent());
    playerEntity.add(HealthComponent(maxHealth: 100));
    playerEntity.add(PlayerComponent(
        sessionId: sid, isLocalPlayer: isLocalPlayer, isHost: isHost));
    playerEntity.add(TagsComponent({'player'}));
    playerEntity.add(CollisionComponent(
        tag: 'player', radius: 10, collidesWith: {'meteor'}));
    playerEntity.add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(playerEntity);
    if (isLocalPlayer) {
      world.rootEntity
          .get<BlackboardComponent>()
          ?.set('local_player_id', playerEntity.id);
    }
    _networkEntityMap[sid] = playerEntity.id;
    debugPrint(
        '[NetworkSystem] ✨ Created player entity. SID: $sid, LocalID: ${playerEntity.id}, isHost: $isHost');
    return playerEntity;
  }

  void _updateStatus(String m, {bool isConnected = false}) {
    world.rootEntity
        .add(NetworkStateComponent(isConnected: isConnected, statusMessage: m));
  }

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}

  @override
  void onRemovedFromWorld() {
    _socket?.dispose();
    _networkEntityMap.clear();
    super.onRemovedFromWorld();
  }
}
