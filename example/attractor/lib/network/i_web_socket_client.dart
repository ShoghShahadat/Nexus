import 'dart:async';
import 'dart:typed_data';

/// An abstract interface for a WebSocket client.
/// این یک اینترفیس انتزاعی برای کلاینت وب‌سوکت است.
///
/// This contract decouples the NetworkSystem from the actual implementation,
/// allowing for easier testing and swapping of WebSocket libraries.
/// این قرارداد، NetworkSystem را از پیاده‌سازی واقعی جدا می‌کند و امکان
/// تست و تعویض آسان کتابخانه‌های وب‌سوکت را فراهم می‌کند.
abstract class IWebSocketClient {
  /// A stream that emits data received from the server.
  /// استریمی که داده‌های دریافتی از سرور را منتشر می‌کند.
  Stream<Uint8List> get onMessage;

  /// A stream that emits connection status changes.
  /// استریمی که تغییرات وضعیت اتصال را منتشر می‌کند.
  Stream<bool> get onConnectionStateChange;

  /// Establishes a connection to the WebSocket server.
  /// یک اتصال به سرور وب‌سوکت برقرار می‌کند.
  Future<void> connect(String url);

  /// Sends binary data to the connected server.
  /// داده‌های باینری را به سرور متصل ارسال می‌کند.
  void send(Uint8List data);

  /// Closes the WebSocket connection.
  /// اتصال وب‌سوکت را می‌بندد.
  void disconnect();
}
