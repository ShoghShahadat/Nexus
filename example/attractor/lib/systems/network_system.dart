import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../components/network_components.dart';
import '../events.dart';

/// Manages the client-side connection and state synchronization with the REAL game server.
class NetworkSystem extends System {
  final String serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _serverSubscription;

  final BinaryWorldSerializer _serializer;
  final Map<int, Entity> _serverEntityMap = {};

  NetworkSystem(this._serializer, {required this.serverUrl});

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _connect();
    listen<SendDirectionalInputEvent>(_onSendInput);
  }

  void _connect() {
    if (_channel != null) return;
    _updateStatus('Connecting to $serverUrl...');

    try {
      // --- CRITICAL FIX & DEBUGGING ---
      // Instead of parsing the string, we construct the Uri directly to avoid parsing issues.
      // We also add a print statement to see the exact URI being used.
      final uri = Uri.parse(serverUrl); // Using parse again, but with logging

      if (kDebugMode) {
        print(
            '[NetworkSystem] Attempting to connect to WebSocket: ${uri.toString()}');
      }

      _channel = WebSocketChannel.connect(uri);

      _serverSubscription = _channel!.stream.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (e) {
          if (kDebugMode) {
            print('[NetworkSystem] WebSocket Error: $e');
          }
          _onDisconnect(error: e.toString());
        },
        cancelOnError: true,
      );
      _updateStatus('Connected!', isConnected: true);
    } catch (e) {
      if (kDebugMode) {
        print('[NetworkSystem] Connection failed: ${e.toString()}');
      }
      _onDisconnect(error: "Connection failed: ${e.toString()}");
    }
  }

  void _onData(dynamic data) {
    if (data is Uint8List) {
      final decodedWorld = _serializer.decode(data);
      final receivedServerIds = decodedWorld.keys.toSet();

      for (final serverId in receivedServerIds) {
        final components = decodedWorld[serverId]!;
        var clientEntity = _serverEntityMap[serverId];

        if (clientEntity == null) {
          clientEntity = Entity();
          clientEntity.add(LifecyclePolicyComponent(isPersistent: true));
          world.addEntity(clientEntity);
          _serverEntityMap[serverId] = clientEntity;
        }
        clientEntity.addComponents(components);
      }

      final serverIdsToRemove =
          _serverEntityMap.keys.toSet().difference(receivedServerIds);
      for (final serverId in serverIdsToRemove) {
        final clientEntity = _serverEntityMap.remove(serverId);
        if (clientEntity != null) {
          world.removeEntity(clientEntity.id);
        }
      }

      final localPlayerEntity = world.entities.values.firstWhereOrNull((e) {
        final playerComp = e.get<PlayerComponent>();
        return playerComp != null && playerComp.isLocalPlayer;
      });

      if (localPlayerEntity != null) {
        world.rootEntity
            .get<BlackboardComponent>()
            ?.set('local_player_id', localPlayerEntity.id);

        final playerComp = localPlayerEntity.get<PlayerComponent>()!;
        playerComp.isLocalPlayer = false;
        localPlayerEntity.add(playerComp);
      }
    }
  }

  void _onSendInput(SendDirectionalInputEvent event) {
    if (_channel != null) {
      final writer = BinaryWriter();
      writer.writeInt32(1);
      writer.writeDouble(event.dx);
      writer.writeDouble(event.dy);
      _channel!.sink.add(writer.toBytes());
    }
  }

  void _onDisconnect({String? error}) {
    _serverSubscription?.cancel();
    _channel?.sink.close();
    _serverSubscription = null;
    _channel = null;
    _updateStatus(error ?? 'Disconnected.', isConnected: false);
    world.rootEntity.get<BlackboardComponent>()?.remove('local_player_id');

    // Attempt to reconnect after a delay.
    Future.delayed(const Duration(seconds: 3), () {
      if (world.systems.contains(this)) _connect();
    });
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
    _serverSubscription?.cancel();
    _channel?.sink.close();
    _serverEntityMap.clear();
    super.onRemovedFromWorld();
  }
}
