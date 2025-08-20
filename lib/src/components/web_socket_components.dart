import 'package:nexus/nexus.dart';

/// Represents the current status of a WebSocket connection.
/// وضعیت فعلی یک اتصال WebSocket را نشان می‌دهد.
enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error,
}

/// A logic-only component that initiates a WebSocket connection for an entity.
/// یک کامپوننت فقط-منطقی که یک اتصال WebSocket را برای یک موجودیت آغاز می‌کند.
///
/// This component is NOT serializable. Add it to an entity to instruct the
/// `WebSocketSystem` to establish and manage a connection.
/// این کامپوننت سریالایزبل نیست. آن را به یک موجودیت اضافه کنید تا به `WebSocketSystem`
/// دستور دهد یک اتصال را برقرار و مدیریت کند.
class WebSocketRequestComponent extends Component {
  final String url;
  final Iterable<String>? protocols;

  /// A mandatory parser function that converts each raw message from the socket
  /// into a specific data component or a list of components.
  /// یک تابع پارسر اجباری که هر پیام خام از سوکت را به یک یا چند کامپوننت داده‌ای
  /// مشخص تبدیل می‌کند.
  final List<Component> Function(dynamic data) onParseMessage;

  /// An optional event fired when the connection is successfully established.
  /// یک رویداد اختیاری که هنگام برقراری موفقیت‌آمیز اتصال منتشر می‌شود.
  final dynamic onConnectedEvent;

  /// An optional event fired when the connection is closed or lost.
  /// یک رویداد اختیاری که هنگام بسته شدن یا از دست رفتن اتصال منتشر می‌شود.
  final dynamic onDisconnectedEvent;

  WebSocketRequestComponent({
    required this.url,
    required this.onParseMessage,
    this.protocols,
    this.onConnectedEvent,
    this.onDisconnectedEvent,
  });

  @override
  List<Object?> get props =>
      [url, protocols, onParseMessage, onConnectedEvent, onDisconnectedEvent];
}

/// A serializable component that holds the current state of a WebSocket connection.
/// یک کامپوننت سریالایزبل که وضعیت فعلی یک اتصال WebSocket را نگهداری می‌کند.
///
/// This component is managed by the `WebSocketSystem` and can be used by the
/// UI to reflect the connection status.
/// این کامپوننت توسط `WebSocketSystem` مدیریت می‌شود و می‌تواند توسط UI برای
/// نمایش وضعیت اتصال استفاده شود.
class WebSocketStateComponent extends Component with SerializableComponent {
  final WebSocketStatus status;
  final String? errorMessage;

  WebSocketStateComponent({
    this.status = WebSocketStatus.connecting,
    this.errorMessage,
  });

  factory WebSocketStateComponent.fromJson(Map<String, dynamic> json) {
    return WebSocketStateComponent(
      status: WebSocketStatus.values[json['status'] as int],
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'status': status.index,
        'errorMessage': errorMessage,
      };

  @override
  List<Object?> get props => [status, errorMessage];
}
