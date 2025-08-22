import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';

class _Player {
  final int sessionId;
  final Entity entity;
  final StreamController<Uint8List> toClientController;

  _Player(this.sessionId, this.entity, this.toClientController);
}

/// A mock WebSocket server that runs in-process and communicates via streams.
class MockServer {
  static const double playerMoveSpeed = 300.0;
  static const double playerBaseSize = 20.0;

  final NexusWorld _world;
  final BinaryWorldSerializer _serializer;
  final Map<int, _Player> _players = {};
  int _nextSessionId = 1;
  Timer? _gameLoopTimer;
  final _stopwatch = Stopwatch();

  final _fromClientsController =
      StreamController<({int sessionId, Uint8List data})>.broadcast();

  MockServer(NexusWorld Function() serverWorldProvider, this._serializer)
      : _world = serverWorldProvider() {
    _fromClientsController.stream.listen(_handleMessage);
  }

  Future<void> start() async {
    await _world.init();
    print('[SERVER] Mock server started.');
    _stopwatch.start();
    _gameLoopTimer =
        Timer.periodic(const Duration(milliseconds: 16), _gameLoop);
  }

  Stream<Uint8List> connectClient(Stream<Uint8List> fromClient) {
    final sessionId = _nextSessionId++;
    print('[SERVER] Player connected with session ID: $sessionId');

    final toClientController = StreamController<Uint8List>.broadcast();

    fromClient.listen((data) {
      _fromClientsController.add((sessionId: sessionId, data: data));
    }, onDone: () => _handleDisconnect(sessionId));

    final playerEntity = _createPlayerEntity(sessionId);
    final player = _Player(sessionId, playerEntity, toClientController);
    _players[sessionId] = player;

    _sendInitialState(player);

    return toClientController.stream;
  }

  Entity _createPlayerEntity(int sessionId) {
    final playerEntity = Entity();
    final screenInfo = _world.rootEntity.get<ScreenInfoComponent>();
    final startX = Random().nextDouble() * (screenInfo?.width ?? 800);
    final startY = (screenInfo?.height ?? 600) * 0.8;

    playerEntity.add(PositionComponent(
        x: startX, y: startY, width: playerBaseSize, height: playerBaseSize));
    playerEntity.add(VelocityComponent());
    playerEntity.add(HealthComponent(maxHealth: 100));
    playerEntity.add(PlayerComponent(sessionId: sessionId));
    playerEntity.add(TagsComponent({'player'}));
    playerEntity.add(CollisionComponent(
        tag: 'player',
        radius: playerBaseSize / 2,
        collidesWith: {'meteor', 'health_orb'}));
    playerEntity.add(LifecyclePolicyComponent(isPersistent: true));
    _world.addEntity(playerEntity);
    return playerEntity;
  }

  void _sendInitialState(_Player player) {
    final playerComponent = player.entity.get<PlayerComponent>()!;
    playerComponent.isLocalPlayer = true;
    player.entity.add(playerComponent);

    final packet = _serializer.serialize(_world.entities.values.toList());
    player.toClientController.add(packet);

    playerComponent.isLocalPlayer = false;
    player.entity.add(playerComponent);
  }

  void _handleMessage(({int sessionId, Uint8List data}) message) {
    final reader = BinaryReader(message.data);
    final messageType = reader.readInt32();

    if (messageType == 1) {
      final dx = reader.readDouble();
      final dy = reader.readDouble();
      final playerEntity = _players[message.sessionId]?.entity;
      final health = playerEntity?.get<HealthComponent>();

      if (playerEntity != null && (health?.currentHealth ?? 0) > 0) {
        final vel = playerEntity.get<VelocityComponent>()!;
        vel.x = dx * playerMoveSpeed;
        vel.y = dy * playerMoveSpeed;
        playerEntity.add(vel);
      }
    }
  }

  void _handleDisconnect(int sessionId) {
    print('[SERVER] Player disconnected: $sessionId');
    final player = _players.remove(sessionId);
    if (player != null) {
      player.toClientController.close();
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

    final entitiesToSync = _world.entities.values
        .where((e) => e.allComponents.any((c) => c is BinaryComponent))
        .toList();

    if (entitiesToSync.isEmpty) return;

    final packet = _serializer.serialize(entitiesToSync);
    if (packet.isEmpty) return;

    for (final player in _players.values) {
      player.toClientController.add(packet);
    }
  }

  void stop() {
    _gameLoopTimer?.cancel();
    for (final player in _players.values) {
      player.toClientController.close();
    }
    _fromClientsController.close();
    _world.clear();
    print('[SERVER] Mock server stopped.');
  }
}
