// ==============================================================================
// File: lib/systems/network_system.dart
// Author: Your Intelligent Assistant
// Version: 13.0
// Description: Manages client-side connection and state synchronization.
// Changes:
// - CRITICAL FIX: Now uses Base64 encoding/decoding for all binary data transfer.
//   This is the standard and robust solution to prevent data corruption over
//   Socket.IO, resolving the deserialization crash on the second client.
// - FIX: Added LifecyclePolicyComponent to created meteors to remove warnings.
// - STYLE: Removed redundant 'as dynamic' cast for clarity.
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:nexus/nexus.dart' hide SpawnerComponent, LifecycleComponent;
import '../components/interpolation_component.dart';
import '../components/network_components.dart';
import '../components/server_logic_components.dart';
import '../network/i_web_socket_client.dart';

class NetworkSystem extends System {
  final String serverUrl;
  final BinaryWorldSerializer _serializer;
  late final IWebSocketClient _webSocketClient;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionStateSubscription;

  final Map<String, EntityId> _remoteClientMap = {};
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
      if (world.entities.values.where((e) => e.has<PlayerComponent>()).length <=
          1) {
        final spawner = Entity()
          ..add(TagsComponent({'meteor_spawner'}))
          ..add(SpawnerComponent(prefab: _createMeteorPrefab));
        world.addEntity(spawner);
      }
    } else {
      _updateStatus('Connecting to $serverUrl...', isConnected: false);
      _remoteClientMap.values.forEach(world.removeEntity);
      _remoteClientMap.clear();
    }
  }

  void _onData(Uint8List data) {
    final messageString = utf8.decode(data);
    final message = jsonDecode(messageString);

    if (message['event'] == 'state_broadcast') {
      final senderId = message['data']['sender_id'] as String;
      final payload = base64Decode(message['data']['payload'] as String);

      final decoded = _serializer.decode(payload);

      EntityId remoteEntityId;
      if (_remoteClientMap.containsKey(senderId)) {
        remoteEntityId = _remoteClientMap[senderId]!;
      } else {
        final newEntity = Entity()
          ..add(LifecyclePolicyComponent(isPersistent: true))
          ..add(TagsComponent({'player'}))
          ..add(PositionComponent(width: 20, height: 20));
        world.addEntity(newEntity);
        _remoteClientMap[senderId] = newEntity.id;
        remoteEntityId = newEntity.id;
      }

      final entity = world.entities[remoteEntityId];
      if (entity != null && decoded.isNotEmpty) {
        final components = decoded.values.first;
        entity.addComponents(components);
      }
    } else if (message['event'] == 'client_left') {
      final leftClientId = message['data']['id'] as String;
      final localEntityId = _remoteClientMap.remove(leftClientId);
      if (localEntityId != null) {
        world.removeEntity(localEntityId);
      }
    }
  }

  @override
  bool matches(Entity entity) => entity.has<OwnedComponent>();

  @override
  void update(Entity entity, double dt) {
    _timeSinceLastSend += dt;
    if (_timeSinceLastSend >= sendInterval) {
      _timeSinceLastSend = 0;

      final ownedEntities =
          world.entities.values.where((e) => e.has<OwnedComponent>()).toList();

      if (ownedEntities.isNotEmpty) {
        final packet = _serializer.serialize(ownedEntities);
        final base64Packet = base64Encode(packet);
        // --- STYLE: Removed redundant cast ---
        _webSocketClient.send(base64Packet);
      }
    }
  }

  Entity _createMeteorPrefab() {
    final random = Random();
    final initialSpeed = random.nextDouble() * 100 + 150;
    return Entity()
      ..add(OwnedComponent())
      ..add(PositionComponent(
          x: random.nextDouble() * 800, y: -50, width: 30, height: 30))
      ..add(
          VelocityComponent(x: random.nextDouble() * 100 - 50, y: initialSpeed))
      ..add(TagsComponent({'meteor'}))
      ..add(DamageComponent(25))
      ..add(TargetingComponent(turnSpeed: 1.5))
      ..add(LifecycleComponent(
          maxAge: 5.0,
          initialSpeed: initialSpeed,
          initialWidth: 30,
          initialHeight: 30))
      ..add(LifecyclePolicyComponent(
          destructionCondition: (e) =>
              (e.get<LifecycleComponent>()?.age ?? 0) >=
              (e.get<LifecycleComponent>()?.maxAge ?? 999)));
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
