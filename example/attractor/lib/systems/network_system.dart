import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/binary_reader_writer.dart';
import 'package:nexus/src/core/serialization/binary_world_serializer.dart';
import '../components/network_components.dart';
import '../events.dart';
import '../network/mock_server.dart';

/// Manages the client-side connection to the game server.
class NetworkSystem extends System {
  final BinaryWorldSerializer _serializer;
  StreamSubscription? _serverSubscription;
  StreamController<Uint8List>? _toServerController;
  MockServer? _server;

  NetworkSystem(this._serializer);

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Get the server instance from the service locator.
    _server = world.services.get<MockServer>();
    _connect();
    listen<SendInputEvent>(_onSendInput);
  }

  void _connect() {
    if (_server == null || _toServerController != null) return;
    _updateStatus('Connecting...');

    _toServerController = StreamController<Uint8List>.broadcast();
    final fromServerStream =
        _server!.connectClient(_toServerController!.stream);

    _serverSubscription = fromServerStream.listen(
      _onData,
      onDone: _onDisconnect,
      onError: (e) => _onDisconnect(error: e.toString()),
      cancelOnError: true,
    );
    _updateStatus('Connected!', isConnected: true);
  }

  void _onData(dynamic data) {
    if (data is Uint8List) {
      // --- FIX: The deserializer now handles creating/removing entities ---
      _serializer.deserialize(world, data);

      // After deserializing, find the local player and update the blackboard.
      // This logic is now more robust as the entity is guaranteed to exist.
      final localPlayerEntity = world.entities.values.firstWhereOrNull((e) {
        final playerComp = e.get<PlayerComponent>();
        return playerComp != null && playerComp.isLocalPlayer;
      });

      if (localPlayerEntity != null) {
        final blackboard = world.rootEntity.get<BlackboardComponent>();
        if (blackboard != null) {
          blackboard.set('local_player_id', localPlayerEntity.id);
          world.rootEntity.add(blackboard);
        }

        // The server sets this flag to true only for the initial packet.
        // We set it back to false on the client so it's not permanently marked.
        final playerComp = localPlayerEntity.get<PlayerComponent>()!;
        playerComp.isLocalPlayer = false;
        localPlayerEntity.add(playerComp);
      }
    }
  }

  void _onSendInput(SendInputEvent event) {
    if (_toServerController != null && !_toServerController!.isClosed) {
      final writer = BinaryWriter();
      writer.writeInt32(1); // Message Type: Player Input
      writer.writeDouble(event.x);
      writer.writeDouble(event.y);
      _toServerController!.add(writer.toBytes());
    }
  }

  void _onDisconnect({String? error}) {
    _serverSubscription?.cancel();
    _toServerController?.close();
    _serverSubscription = null;
    _toServerController = null;
    _updateStatus(error ?? 'Disconnected.', isConnected: false);
    world.rootEntity.get<BlackboardComponent>()?.remove('local_player_id');

    // Attempt to reconnect after a delay.
    Future.delayed(const Duration(seconds: 3), () {
      if (world.systems.contains(this)) {
        _connect();
      }
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
    _toServerController?.close();
    super.onRemovedFromWorld();
  }
}
