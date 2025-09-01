import 'dart:async';
import 'package:nexus/nexus.dart';

/// A system that manages WebSocket connections for entities.
///
/// It processes entities with `WebSocketRequestComponent` to establish connections
/// using the registered `IWebSocketService`. It listens to incoming messages,
/// parses them into components, and updates the entity's state.
///
/// --- RE-ARCHITECTED as a ReactiveSystem ---
/// This system now reacts to the ADDITION of a WebSocketRequestComponent,
/// making it far more efficient as it doesn't run in the main update loop.
class WebSocketSystem extends ReactiveSystem {
  late final IWebSocketService _webSocketService;
  bool _isServiceInitialized = false;
  final Map<EntityId, StreamSubscription> _subscriptions = {};

  @override
  Set<Type> get subscribedComponentTypes => {WebSocketRequestComponent};

  @override
  Future<void> init() async {
    try {
      _webSocketService = services.get<IWebSocketService>();
      _isServiceInitialized = true;
    } catch (e) {
      print(
          '[WebSocketSystem] FATAL ERROR: IWebSocketService not found in GetIt. Please register your WebSocket service implementation.');
      _isServiceInitialized = false;
    }
  }

  /// This is the core logic, triggered ONLY when a WebSocketRequestComponent is added.
  @override
  void onComponentChanged(
      Entity entity, Component? oldComponent, Component newComponent) {
    if (!_isServiceInitialized || newComponent is! WebSocketRequestComponent) {
      return;
    }

    final request = newComponent;
    // Immediately remove the request component to prevent re-processing.
    Future.microtask(() => entity.remove<WebSocketRequestComponent>());

    // Set initial state.
    // --- FIX: Pass the required connectionId to the state component. ---
    // --- اصلاح: connectionId الزامی را به کامپوننت وضعیت پاس می‌دهد. ---
    entity.add(WebSocketStateComponent(
        connectionId: request.connectionId,
        status: WebSocketStatus.connecting));

    try {
      // --- FIX: Pass the connectionId to the connect method. ---
      // --- اصلاح: connectionId را به متد connect پاس می‌دهد. ---
      final stream = _webSocketService.connect(
        request.connectionId,
        request.url,
        protocols: request.protocols,
      );

      // --- FIX: Pass the required connectionId to the state component. ---
      // --- اصلاح: connectionId الزامی را به کامپوننت وضعیت پاس می‌دهد. ---
      entity.add(WebSocketStateComponent(
          connectionId: request.connectionId,
          status: WebSocketStatus.connected));
      if (request.onConnectedEvent != null) {
        world.eventBus.fire(request.onConnectedEvent);
      }

      final subscription = stream.listen(
        (data) {
          final components = request.onParseMessage(data);
          for (final component in components) {
            entity.add(component);
          }
        },
        onError: (error) {
          // --- FIX: Pass the required connectionId to the state component. ---
          // --- اصلاح: connectionId الزامی را به کامپوننت وضعیت پاس می‌دهد. ---
          entity.add(WebSocketStateComponent(
            connectionId: request.connectionId,
            status: WebSocketStatus.error,
            errorMessage: error.toString(),
          ));
          _cleanupConnection(entity.id, request);
        },
        onDone: () {
          // --- FIX: Pass the required connectionId to the state component. ---
          // --- اصلاح: connectionId الزامی را به کامپوننت وضعیت پاس می‌دهد. ---
          entity.add(WebSocketStateComponent(
              connectionId: request.connectionId,
              status: WebSocketStatus.disconnected));
          _cleanupConnection(entity.id, request);
        },
      );

      _subscriptions[entity.id] = subscription;
    } catch (e) {
      // --- FIX: Pass the required connectionId to the state component. ---
      // --- اصلاح: connectionId الزامی را به کامپوننت وضعیت پاس می‌دهد. ---
      entity.add(WebSocketStateComponent(
        connectionId: request.connectionId,
        status: WebSocketStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  void onComponentRemoved(Entity entity, Component removedComponent) {
    // This system doesn't need to react to removal of its trigger component,
    // as it removes it itself immediately after processing.
  }

  @override
  void onEntityRemoved(Entity entity) {
    // Attempt to find the request info if the entity is removed unexpectedly
    final state = entity.get<WebSocketStateComponent>();
    if (state != null) {
      _cleanupConnectionById(entity.id, state.connectionId);
    }
    super.onEntityRemoved(entity);
  }

  void _cleanupConnection(EntityId id, WebSocketRequestComponent request) {
    _cleanupConnectionById(id, request.connectionId);
    if (request.onDisconnectedEvent != null) {
      world.eventBus.fire(request.onDisconnectedEvent);
    }
  }

  void _cleanupConnectionById(EntityId id, String connectionId) {
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
    // --- FIX: Pass the connectionId to the disconnect method. ---
    // --- اصلاح: connectionId را به متد disconnect پاس می‌دهد. ---
    _webSocketService.disconnect(connectionId);
  }

  @override
  void onRemovedFromWorld() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _webSocketService.disconnectAll();
    super.onRemovedFromWorld();
  }
}
