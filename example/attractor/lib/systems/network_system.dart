// === File: example/attractor/lib/systems/network_system.dart (Modified) ===

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/binary_world_serializer.dart';
import '../components/network_components.dart';
import '../events.dart';

/// Manages the client-side connection to the game server.
class NetworkSystem extends System {
  final String url;
  final BinaryWorldSerializer _serializer;
  WebSocket? _socket;
  bool _isConnecting = false;
  StreamSubscription? _socketSubscription;

  NetworkSystem(this.url, this._serializer);

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _connect();
    listen<SendInputEvent>(_onSendInput);
  }

  Future<void> _connect() async {
    if (_socket != null || _isConnecting) return;
    _isConnecting = true;
    _updateStatus('Connecting to $url...');

    try {
      _socket = await WebSocket.connect(url);
      _isConnecting = false;
      _updateStatus('Connected!', isConnected: true);

      _socketSubscription = _socket!.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (e) => _onDisconnect(error: e.toString()),
        cancelOnError: true,
      );
    } catch (e) {
      _isConnecting = false;
      _onDisconnect(error: 'Failed to connect: $e');
    }
  }

  void _onData(dynamic data) {
    if (data is Uint8List) {
      _serializer.deserialize(world, data);

      // After deserializing, find our player and update the root blackboard.
      for (final entity in world.entities.values) {
        final playerComp = entity.get<PlayerComponent>();
        if (playerComp != null && playerComp.isLocalPlayer) {
          world.rootEntity
              .get<BlackboardComponent>()
              ?.set('local_player_id', entity.id);
          // Unset the flag on the client to avoid confusion
          playerComp.isLocalPlayer = false;
          entity.add(playerComp);
          break;
        }
      }
    }
  }

  void _onSendInput(SendInputEvent event) {
    if (_socket?.readyState == WebSocket.open) {
      final writer = BinaryWriter();
      writer.writeInt32(1); // Message Type: Player Input
      writer.writeDouble(event.x);
      writer.writeDouble(event.y);
      _socket!.add(writer.toBytes());
    }
  }

  void _onDisconnect({String? error}) {
    _socket?.close();
    _socket = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _updateStatus(error ?? 'Disconnected.', isConnected: false);
    world.rootEntity.get<BlackboardComponent>()?.remove('local_player_id');

    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnecting && world.systems.contains(this)) _connect();
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
    _socketSubscription?.cancel();
    _socket?.close();
    super.onRemovedFromWorld();
  }
}
