// ==============================================================================
// File: lib/systems/network_system.dart
// Author: Your Intelligent Assistant
// Version: 25.0
// Description: Manages client-side connection and state synchronization.
// Changes:
// - PERSONALIZED CHALLENGE: The meteor spawning logic in `_createMeteorPrefab`
//   has been updated. It no longer targets a random player. Instead, it now
//   specifically finds the local player (the one with ControlledPlayerComponent)
//   and sets them as the meteor's target. This ensures each player only has
//   to deal with meteors created for them.
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart' hide SpawnerComponent, LifecycleComponent;
import '../components/interpolation_component.dart';
import '../components/meteor_component.dart';
import '../components/network_components.dart';
import '../components/server_logic_components.dart';
import '../network/i_web_socket_client.dart';
import 'player_control_system.dart';

class NetworkSystem extends System {
  final String serverUrl;
  final BinaryWorldSerializer _serializer;
  late final IWebSocketClient _webSocketClient;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionStateSubscription;

  final Map<String, Map<EntityId, EntityId>> _remoteEntityIdMap = {};
  double _timeSinceLastSend = 0.0;
  static const double sendInterval = 1.0 / 30.0;

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

  void _onConnectionStateChanged(bool isConnected) {
    if (isConnected) {
      _updateStatus('Connected!', isConnected: true);
      final hasSpawner = world.entities.values.any(
          (e) => e.get<TagsComponent>()?.hasTag('meteor_spawner') ?? false);
      if (!hasSpawner) {
        final spawner = Entity()
          ..add(TagsComponent({'meteor_spawner'}))
          ..add(SpawnerComponent(prefab: _createMeteorPrefab));
        world.addEntity(spawner);
      }
    } else {
      _updateStatus('Connecting to $serverUrl...', isConnected: false);
      _remoteEntityIdMap.values.forEach((entityMap) {
        entityMap.values.forEach(world.removeEntity);
      });
      _remoteEntityIdMap.clear();
    }
  }

  void _onData(Uint8List data) {
    final messageString = utf8.decode(data);
    final message = jsonDecode(messageString);

    if (message['event'] == 'state_broadcast') {
      final senderId = message['data']['sender_id'] as String;
      final payload = base64Decode(message['data']['payload'] as String);
      final decodedEntities = _serializer.decode(payload);

      _remoteEntityIdMap.putIfAbsent(senderId, () => {});
      final senderEntityMap = _remoteEntityIdMap[senderId]!;

      decodedEntities.forEach((remoteEntityId, components) {
        if (!components.any((c) => c is PlayerComponent)) return;

        EntityId? localEntityId = senderEntityMap[remoteEntityId];
        Entity? localEntity =
            localEntityId != null ? world.entities[localEntityId] : null;

        if (localEntity == null) {
          final newEntity = Entity();
          world.addEntity(newEntity);
          localEntityId = newEntity.id;
          localEntity = newEntity;
          senderEntityMap[remoteEntityId] = localEntityId;

          newEntity.add(TagsComponent({'player'}));
          newEntity.add(LifecyclePolicyComponent(isPersistent: true));
          localEntity.addComponents(components);
        } else {
          final posComponent =
              components.firstWhereOrNull((c) => c is PositionComponent)
                  as PositionComponent?;

          if (posComponent != null) {
            localEntity.add(NetworkSyncComponent(
              targetX: posComponent.x,
              targetY: posComponent.y,
              targetWidth: posComponent.width,
              targetHeight: posComponent.height,
            ));
            components.remove(posComponent);
          }
          localEntity.addComponents(components);
        }
      });
    } else if (message['event'] == 'client_left') {
      final leftClientId = message['data']['id'] as String;
      final senderEntityMap = _remoteEntityIdMap.remove(leftClientId);
      if (senderEntityMap != null) {
        senderEntityMap.values.forEach(world.removeEntity);
      }
    }
  }

  @override
  bool matches(Entity entity) =>
      entity.get<TagsComponent>()?.hasTag('root') ?? false;

  @override
  void update(Entity entity, double dt) {
    _timeSinceLastSend += dt;
    if (_timeSinceLastSend < sendInterval) return;
    _timeSinceLastSend = 0;

    final ownedEntities =
        world.entities.values.where((e) => e.has<OwnedComponent>()).toList();

    if (ownedEntities.isNotEmpty) {
      final packet = _serializer.serialize(ownedEntities);
      if (packet.isNotEmpty) {
        final base64Packet = base64Encode(packet);
        _webSocketClient.send(base64Packet);
      }
    }
  }

  Entity _createMeteorPrefab() {
    final random = Random();
    // --- CHANGE: Find the local player specifically ---
    final localPlayer = world.entities.values
        .firstWhereOrNull((e) => e.has<ControlledPlayerComponent>());

    // If the local player doesn't exist for some reason, don't spawn a meteor.
    if (localPlayer == null) return Entity();

    final targetPlayerId = localPlayer.id;

    final initialSpeed = PlayerControlSystem.playerSpeed * 3.0;
    final meteor = Entity();

    // Meteors are always local, so no OwnedComponent is needed.
    meteor.addComponents([
      PositionComponent(
          x: random.nextDouble() * 800, y: -50, width: 30, height: 30),
      VelocityComponent(x: random.nextDouble() * 100 - 50, y: initialSpeed),
      TagsComponent({'meteor'}),
      DamageComponent(20),
      // --- CHANGE: Target is now always the local player ---
      TargetingComponent(targetId: targetPlayerId, turnSpeed: 1.5),
      LifecycleComponent(
          maxAge: 4.0,
          initialSpeed: initialSpeed,
          initialWidth: 30,
          initialHeight: 30),
      LifecyclePolicyComponent(
          destructionCondition: (e) =>
              (e.get<LifecycleComponent>()?.age ?? 0) >=
              (e.get<LifecycleComponent>()?.maxAge ?? 999))
    ]);

    return meteor;
  }

  void _updateStatus(String message, {bool isConnected = false}) {
    world.rootEntity.add(NetworkStateComponent(
        isConnected: isConnected, statusMessage: message));
  }

  @override
  void onRemovedFromWorld() {
    _messageSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _webSocketClient.disconnect();
    super.onRemovedFromWorld();
  }
}
