import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../events.dart';
import '../network/mock_server.dart';

/// Manages the client-side connection and state synchronization with the game server.
class NetworkSystem extends System {
  final BinaryWorldSerializer _serializer;
  StreamSubscription? _serverSubscription;
  StreamController<Uint8List>? _toServerController;
  MockServer? _server;

  final Map<int, Entity> _serverEntityMap = {};

  NetworkSystem(this._serializer);

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _server = world.services.get<MockServer>();
    _connect();
    // --- FIX: Listen for the correct event to send to the server ---
    listen<SendDirectionalInputEvent>(_onSendInput);
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

  // --- FIX: Method updated to handle the correct event type ---
  void _onSendInput(SendDirectionalInputEvent event) {
    if (_toServerController != null && !_toServerController!.isClosed) {
      final writer = BinaryWriter();
      writer.writeInt32(1); // Message Type: Directional Input
      writer.writeDouble(event.dx);
      writer.writeDouble(event.dy);
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
    _toServerController?.close();
    _serverEntityMap.clear();
    super.onRemovedFromWorld();
  }
}
