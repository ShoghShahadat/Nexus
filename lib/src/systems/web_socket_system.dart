import 'dart:async';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/web_socket_components.dart';
import 'package:nexus/src/services/network/i_web_socket_service.dart';

/// A system that manages WebSocket connections for entities.
/// سیستمی که اتصالات WebSocket را برای موجودیت‌ها مدیریت می‌کند.
///
/// It processes entities with `WebSocketRequestComponent` to establish connections
/// using the registered `IWebSocketService`. It listens to incoming messages,
/// parses them into components, and updates the entity's state.
/// این سیستم موجودیت‌های دارای `WebSocketRequestComponent` را برای برقراری اتصال
/// با استفاده از `IWebSocketService` ثبت‌شده، پردازش می‌کند. به پیام‌های ورودی گوش داده،
/// آن‌ها را به کامپوننت‌ها پارس کرده و وضعیت موجودیت را به‌روز می‌کند.
class WebSocketSystem extends System {
  late final IWebSocketService _webSocketService;
  bool _isServiceInitialized = false;
  final Map<EntityId, StreamSubscription> _subscriptions = {};

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

  @override
  bool matches(Entity entity) {
    return entity.has<WebSocketRequestComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    if (!_isServiceInitialized) return;

    final request = entity.get<WebSocketRequestComponent>()!;
    // Remove the request component to prevent re-processing.
    // کامپوننت درخواست را برای جلوگیری از پردازش مجدد، حذف می‌کنیم.
    entity.remove<WebSocketRequestComponent>();

    // Set initial state.
    // وضعیت اولیه را تنظیم می‌کنیم.
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
          // On each message, parse it into components and add them to the entity.
          // با هر پیام، آن را به کامپوننت‌ها پارس کرده و به موجودیت اضافه می‌کنیم.
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
  void onEntityRemoved(Entity entity) {
    // Ensure we clean up the subscription if the entity is removed.
    // اطمینان حاصل می‌کنیم که در صورت حذف موجودیت، اشتراک (subscription) پاک‌سازی شود.
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
    // Clean up all active connections when the world is destroyed.
    // تمام اتصالات فعال را هنگام از بین رفتن دنیا، پاک‌سازی می‌کنیم.
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _webSocketService.disconnect();
    super.onRemovedFromWorld();
  }
}
