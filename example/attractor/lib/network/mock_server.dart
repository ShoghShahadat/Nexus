import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/binary_world_serializer.dart';
import '../components/network_components.dart';

// A simple data class to hold player state on the server.
class _Player {
  final WebSocket socket;
  final int sessionId;
  final Entity entity;
  _Player(this.socket, this.sessionId, this.entity);
}

/// A mock WebSocket server that runs in-process with the Flutter app.
/// This simulates the logic of a dedicated Python server for development.
class MockServer {
  final NexusWorld _world;
  final BinaryWorldSerializer _serializer;
  HttpServer? _httpServer;
  final Map<int, _Player> _players = {};
  int _nextSessionId = 1;

  MockServer(this._world, this._serializer);

  Future<void> start() async {
    try {
      _httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      print('Mock server listening on ws://localhost:8080');

      _httpServer!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then(_handleConnection);
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('WebSocket connections only')
            ..close();
        }
      });

      // Start the server-side game loop.
      Timer.periodic(const Duration(milliseconds: 33), (_) => _gameLoop());
    } catch (e) {
      print('Error starting mock server: $e');
    }
  }

  void _handleConnection(WebSocket socket) {
    final sessionId = _nextSessionId++;
    print('Player connected with session ID: $sessionId');

    final playerEntity = Entity();
    playerEntity.add(PositionComponent(x: 200, y: 200));
    playerEntity.add(VelocityComponent());
    playerEntity.add(HealthComponent(maxHealth: 100));
    playerEntity.add(PlayerComponent(sessionId: sessionId));
    _world.addEntity(playerEntity);

    final player = _Player(socket, sessionId, playerEntity);
    _players[sessionId] = player;

    socket.listen(
      (data) => _handleMessage(sessionId, data),
      onDone: () => _handleDisconnect(sessionId),
      onError: (e) => _handleDisconnect(sessionId),
      cancelOnError: true,
    );
  }

  void _handleMessage(int sessionId, dynamic data) {
    if (data is! Uint8List) return;
    final reader = BinaryReader(data);
    final messageType = reader.readInt32();

    // Message Type 1: Player Input (Mouse Position)
    if (messageType == 1) {
      final x = reader.readDouble();
      final y = reader.readDouble();
      final playerEntity = _players[sessionId]?.entity;
      final pos = playerEntity?.get<PositionComponent>();
      if (pos != null) {
        // In a real game, you'd apply physics, but here we just set it.
        pos.x = x;
        pos.y = y;
        playerEntity!.add(pos);
      }
    }
  }

  void _handleDisconnect(int sessionId) {
    print('Player disconnected: $sessionId');
    final player = _players.remove(sessionId);
    if (player != null) {
      _world.removeEntity(player.entity.id);
    }
  }

  void _gameLoop() {
    // For now, the game loop is simple: just broadcast the state.
    // In the future, this is where meteor spawning, physics, etc. would run.
    _broadcastGameState();
  }

  void _broadcastGameState() {
    if (_players.isEmpty) return;

    // We only need to serialize entities that are relevant to the players.
    final entitiesToSync = _world.entities.values
        .where((e) =>
            e.has<PlayerComponent>() ||
            e.has<TagsComponent>() &&
                (e.get<TagsComponent>()!.hasTag('meteor') ||
                    e.get<TagsComponent>()!.hasTag('health_orb')))
        .toList();

    if (entitiesToSync.isEmpty) return;

    final packet = _serializer.serialize(entitiesToSync);
    for (final player in _players.values) {
      player.socket.add(packet);
    }
  }

  void stop() {
    _httpServer?.close();
    print('Mock server stopped.');
  }
}
