import 'dart:async';
import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../logic/game_logic.dart';

class _PlayerConnection {
  final int sessionId;
  final Entity entity;
  final StreamController<Uint8List> toClientController;

  _PlayerConnection(this.sessionId, this.entity, this.toClientController);
}

/// A mock WebSocket server that runs in-process and communicates via streams.
/// This class is now only responsible for network communication and state sync.
class MockServer {
  static const double playerMoveSpeed = 300.0;
  static const double playerBaseSize = 20.0;

  final GameLogic
      _gameLogic; // The server now HAS a game logic, it IS NOT the game logic.
  final BinaryWorldSerializer _serializer;
  final Map<int, _PlayerConnection> _connections = {};
  int _nextSessionId = 1;
  Timer? _gameLoopTimer;
  final _stopwatch = Stopwatch();

  final _fromClientsController =
      StreamController<({int sessionId, Uint8List data})>.broadcast();

  MockServer(this._gameLogic, this._serializer) {
    _fromClientsController.stream.listen(_handleMessage);
  }

  Future<void> start() async {
    await _gameLogic.init();
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

    // Let the game logic handle creating the player
    final playerEntity = _gameLogic.onPlayerConnected(sessionId);
    final connection =
        _PlayerConnection(sessionId, playerEntity, toClientController);
    _connections[sessionId] = connection;

    _sendInitialState(connection);

    return toClientController.stream;
  }

  void _sendInitialState(_PlayerConnection connection) {
    final playerComponent = connection.entity.get<PlayerComponent>()!;
    playerComponent.isLocalPlayer = true;
    connection.entity.add(playerComponent);

    final packet = _serializer.serialize(_gameLogic.entitiesToSync);
    connection.toClientController.add(packet);

    playerComponent.isLocalPlayer = false;
    connection.entity.add(playerComponent);
  }

  void _handleMessage(({int sessionId, Uint8List data}) message) {
    final reader = BinaryReader(message.data);
    final messageType = reader.readInt32();

    if (messageType == 1) {
      final dx = reader.readDouble();
      final dy = reader.readDouble();
      // Pass the input to the game logic to process
      _gameLogic.handlePlayerInput(message.sessionId, dx, dy);
    }
  }

  void _handleDisconnect(int sessionId) {
    print('[SERVER] Player disconnected: $sessionId');
    final connection = _connections.remove(sessionId);
    if (connection != null) {
      connection.toClientController.close();
      _gameLogic.onPlayerDisconnected(sessionId);
    }
  }

  void _gameLoop(Timer timer) {
    final dt =
        _stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _stopwatch.reset();
    _stopwatch.start();

    _gameLogic.update(dt);
    _broadcastGameState();
  }

  void _broadcastGameState() {
    if (_connections.isEmpty) return;

    final entitiesToSync = _gameLogic.entitiesToSync;
    if (entitiesToSync.isEmpty) return;

    final packet = _serializer.serialize(entitiesToSync);
    if (packet.isEmpty) return;

    for (final connection in _connections.values) {
      connection.toClientController.add(packet);
    }
  }

  void stop() {
    _gameLoopTimer?.cancel();
    for (final connection in _connections.values) {
      connection.toClientController.close();
    }
    _fromClientsController.close();
    _gameLogic.dispose();
    print('[SERVER] Mock server stopped.');
  }
}
