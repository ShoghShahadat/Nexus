import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../events.dart';
import '../network/i_web_socket_client.dart';

/// Manages client-side connection and state synchronization using an abstracted WebSocket client.
/// مدیریت اتصال سمت کلاینت و همگام‌سازی وضعیت با استفاده از یک کلاینت وب‌سوکت انتزاعی.
class NetworkSystem extends System {
  final String serverUrl;
  final BinaryWorldSerializer _serializer;

  // --- NEW: Use the abstracted WebSocket client ---
  // --- جدید: استفاده از کلاینت وب‌سوکت انتزاعی ---
  late final IWebSocketClient _webSocketClient;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionStateSubscription;

  final Map<int, Entity> _serverEntityMap = {};

  NetworkSystem(this._serializer, {required this.serverUrl});

  @override
  Future<void> init() async {
    super.init();
    // --- NEW: Get the WebSocket client from the service locator ---
    // --- جدید: دریافت کلاینت وب‌سوکت از سرویس لوکیتور ---
    _webSocketClient = services.get<IWebSocketClient>();

    _messageSubscription = _webSocketClient.onMessage.listen(_onData);
    _connectionStateSubscription = _webSocketClient.onConnectionStateChange
        .listen(_onConnectionStateChanged);

    await _webSocketClient.connect(serverUrl);
  }

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<SendDirectionalInputEvent>(_onSendInput);
  }

  void _onConnectionStateChanged(bool isConnected) {
    if (isConnected) {
      _updateStatus('Connected!', isConnected: true);
    } else {
      _updateStatus('Connecting to $serverUrl...', isConnected: false);
      world.rootEntity.get<BlackboardComponent>()?.remove('local_player_id');
    }
  }

  void _onData(Uint8List data) {
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

  void _onSendInput(SendDirectionalInputEvent event) {
    final writer = BinaryWriter();
    writer.writeInt32(1); // Message type for input
    writer.writeDouble(event.dx);
    writer.writeDouble(event.dy);
    _webSocketClient.send(writer.toBytes());
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
    _messageSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _webSocketClient.disconnect();
    _serverEntityMap.clear();
    super.onRemovedFromWorld();
  }
}
