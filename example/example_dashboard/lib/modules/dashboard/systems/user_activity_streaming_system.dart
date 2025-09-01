import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

/// A reactive system that manages the WebSocket connection for the User Activity chart.
class UserActivityStreamingSystem extends ReactiveSystem {
  late final IWebSocketService _webSocketService;
  bool _isServiceInitialized = false;
  final Map<EntityId, StreamSubscription> _subscriptions = {};

  // This system reacts to the addition of a WebSocketRequestComponent.
  @override
  Set<Type> get subscribedComponentTypes => {WebSocketRequestComponent};

  @override
  Future<void> init() async {
    try {
      _webSocketService = services.get<IWebSocketService>();
      _isServiceInitialized = true;
    } catch (e) {
      print(
          '[UserActivityStreamingSystem] FATAL ERROR: IWebSocketService not found in GetIt.');
      _isServiceInitialized = false;
    }
  }

  @override
  void onComponentChanged(
      Entity entity, Component? oldComponent, Component newComponent) {
    if (!_isServiceInitialized || newComponent is! WebSocketRequestComponent) {
      return;
    }
    final request = newComponent;

    // Only handle requests intended for this system.
    if (request.connectionId != 'user-activity-stream') {
      return;
    }

    // Immediately remove the request component to prevent re-processing.
    Future.microtask(() => entity.remove<WebSocketRequestComponent>());

    // Set initial state.
    entity.add(WebSocketStateComponent(
        connectionId: request.connectionId,
        status: WebSocketStatus.connecting));

    try {
      final stream =
          _webSocketService.connect(request.connectionId, request.url);

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
          entity.add(WebSocketStateComponent(
            connectionId: request.connectionId,
            status: WebSocketStatus.error,
            errorMessage: error.toString(),
          ));
          _cleanupConnection(entity.id, request);
        },
        onDone: () {
          entity.add(WebSocketStateComponent(
              connectionId: request.connectionId,
              status: WebSocketStatus.disconnected));
          _cleanupConnection(entity.id, request);
        },
      );

      _subscriptions[entity.id] = subscription;
    } catch (e) {
      entity.add(WebSocketStateComponent(
        connectionId: request.connectionId,
        status: WebSocketStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  void onComponentRemoved(Entity entity, Component removedComponent) {
    // Not needed for this system.
  }

  void _cleanupConnection(EntityId id, WebSocketRequestComponent request) {
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
    _webSocketService.disconnect(request.connectionId);
    if (request.onDisconnectedEvent != null) {
      world.eventBus.fire(request.onDisconnectedEvent);
    }
  }

  @override
  void onRemovedFromWorld() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    // Do not call disconnectAll, as other systems might be using the service.
    super.onRemovedFromWorld();
  }
}
