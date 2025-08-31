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
    entity.add(WebSocketStateComponent(status: WebSocketStatus.connecting));

    try {
      final stream = _webSocketService.connect(
        request.url,
        protocols: request.protocols,
      );

      entity.add(WebSocketStateComponent(status: WebSocketStatus.connected));
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
          entity.add(WebSocketStateComponent(
            status: WebSocketStatus.error,
            errorMessage: error.toString(),
          ));
          _cleanupConnection(entity.id, request.onDisconnectedEvent);
        },
        onDone: () {
          entity.add(
              WebSocketStateComponent(status: WebSocketStatus.disconnected));
          _cleanupConnection(entity.id, request.onDisconnectedEvent);
        },
      );

      _subscriptions[entity.id] = subscription;
    } catch (e) {
      entity.add(WebSocketStateComponent(
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

  /// NEW: This lifecycle hook is now inherited from the base System class.
  /// It's the correct place to clean up when an entity is removed from the world.
  @override
  void onEntityRemoved(Entity entity) {
    _cleanupConnection(entity.id, null);
    super.onEntityRemoved(entity);
  }

  void _cleanupConnection(EntityId id, dynamic onDisconnectedEvent) {
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
    if (onDisconnectedEvent != null) {
      world.eventBus.fire(onDisconnectedEvent);
    }
  }

  @override
  void onRemovedFromWorld() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _webSocketService.disconnect();
    super.onRemovedFromWorld();
  }
}
