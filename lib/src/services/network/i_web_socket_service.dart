/// An abstract interface for a WebSocket service.
/// این یک اینترفیس انتزاعی برای سرویس WebSocket است.
///
/// This contract decouples the WebSocketSystem from the actual implementation,
/// allowing developers to use their preferred WebSocket client package.
/// A concrete implementation of this class must be registered with GetIt.
/// این قرارداد، WebSocketSystem را از پیاده‌سازی واقعی جدا می‌کند و به توسعه‌دهندگان
/// اجازه می‌دهد از پکیج کلاینت WebSocket مورد علاقه خود استفاده کنند. یک پیاده‌سازی
/// مشخص از این کلاس باید در GetIt ثبت شود.
abstract class IWebSocketService {
  /// Establishes a connection to the WebSocket server for a given ID.
  /// یک اتصال به سرور WebSocket برای یک شناسه مشخص برقرار می‌کند.
  ///
  /// Returns a stream that emits messages received from the server.
  /// Should throw an exception if the connection fails.
  /// یک استریم برمی‌گرداند که پیام‌های دریافتی از سرور را منتشر می‌کند.
  /// در صورت شکست اتصال، باید یک استثنا پرتاب کند.
  Stream<dynamic> connect(String connectionId, String url,
      {Iterable<String>? protocols});

  /// Sends data to a specific connected WebSocket server.
  /// داده‌ها را به سرور WebSocket متصل و مشخصی ارسال می‌کند.
  void send(String connectionId, dynamic data);

  /// Closes a specific WebSocket connection.
  /// یک اتصال WebSocket مشخص را می‌بندد.
  void disconnect(String connectionId);

  /// Disconnects all active connections.
  /// تمام اتصالات فعال را قطع می‌کند.
  void disconnectAll();
}
