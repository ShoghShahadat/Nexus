import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/binary_world_serializer.dart';
import '../components/network_components.dart';
import '../systems/server_systems.dart';

class _Player {
  final WebSocket socket;
  final int sessionId;
  final Entity entity;
  _Player(this.socket, this.sessionId, this.entity);
}

/// A mock WebSocket server that runs the actual game logic.
class MockServer {
  final NexusWorld _world;
  final BinaryWorldSerializer _serializer;
  HttpServer? _httpServer;
  final Map<int, _Player> _players = {};
  int _nextSessionId = 1;
  Timer? _gameLoopTimer;
  final _stopwatch = Stopwatch();

  MockServer(NexusWorld Function() serverWorldProvider, this._serializer)
      : _world = serverWorldProvider();

  Future<void> start() async {
    try {
      await _world.init();
      _httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      print('[SERVER] Mock server listening on ws://localhost:8080');

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

      _stopwatch.start();
      _gameLoopTimer =
          Timer.periodic(const Duration(milliseconds: 16), _gameLoop);
    } catch (e) {
      print('[SERVER] Error starting mock server: $e');
    }
  }

  void _handleConnection(WebSocket socket) {
    final sessionId = _nextSessionId++;
    print('[SERVER] Player connected with session ID: $sessionId');

    final playerEntity = Entity();
    final startX = Random().nextDouble() *
        (_world.rootEntity.get<ScreenInfoComponent>()?.width ?? 800);
    final startY =
        (_world.rootEntity.get<ScreenInfoComponent>()?.height ?? 600) * 0.8;

    playerEntity
        .add(PositionComponent(x: startX, y: startY, width: 20, height: 20));
    playerEntity.add(VelocityComponent());
    playerEntity.add(HealthComponent(maxHealth: 100));
    playerEntity.add(PlayerComponent(sessionId: sessionId));
    playerEntity.add(TagsComponent({'player'}));
    playerEntity.add(CollisionComponent(
        tag: 'player', radius: 10, collidesWith: {'meteor', 'health_orb'}));
    _world.addEntity(playerEntity);

    final player = _Player(socket, sessionId, playerEntity);
    _players[sessionId] = player;

    // Send a special initial packet to this player so they know who they are.
    _sendInitialState(player);

    socket.listen(
      (data) => _handleMessage(sessionId, data),
      onDone: () => _handleDisconnect(sessionId),
      onError: (e) => _handleDisconnect(sessionId),
      cancelOnError: true,
    );
  }

  void _sendInitialState(_Player player) {
    final playerComponent = player.entity.get<PlayerComponent>()!;
    // Temporarily set the isLocalPlayer flag for this one packet
    playerComponent.isLocalPlayer = true;
    player.entity.add(playerComponent);

    final packet = _serializer.serialize(_world.entities.values.toList());
    player.socket.add(packet);

    // Revert the flag after sending
    playerComponent.isLocalPlayer = false;
    player.entity.add(playerComponent);
  }

  void _handleMessage(int sessionId, dynamic data) {
    if (data is! Uint8List) return;
    final reader = BinaryReader(data);
    final messageType = reader.readInt32();

    if (messageType == 1) {
      // Player Input
      final x = reader.readDouble();
      final y = reader.readDouble();
      final playerEntity = _players[sessionId]?.entity;
      final health = playerEntity?.get<HealthComponent>();
      // Only accept input from players who are alive
      if (playerEntity != null && (health?.currentHealth ?? 0) > 0) {
        final pos = playerEntity.get<PositionComponent>()!;
        pos.x = x;
        pos.y = y;
        playerEntity.add(pos);
      }
    }
  }

  void _handleDisconnect(int sessionId) {
    print('[SERVER] Player disconnected: $sessionId');
    final player = _players.remove(sessionId);
    if (player != null) {
      _world.removeEntity(player.entity.id);
    }
  }

  void _gameLoop(Timer timer) {
    final dt =
        _stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _stopwatch.reset();
    _stopwatch.start();

    _world.update(dt);
    _broadcastGameState();
  }

  void _broadcastGameState() {
    if (_players.isEmpty) return;

    final packet = _serializer.serialize(_world.entities.values.toList());
    if (packet.isEmpty) return;

    for (final player in _players.values) {
      if (player.socket.readyState == WebSocket.open) {
        player.socket.add(packet);
      }
    }
  }

  void stop() {
    _gameLoopTimer?.cancel();
    _httpServer?.close();
    _world.clear();
    print('[SERVER] Mock server stopped.');
  }
}
