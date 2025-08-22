import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'i_web_socket_client.dart';

/// A concrete implementation of [IWebSocketClient] using the `web_socket_channel` package.
/// یک پیاده‌سازی مشخص از [IWebSocketClient] با استفاده از پکیج `web_socket_channel`.
class WebSocketChannelClient implements IWebSocketClient {
  WebSocketChannel? _channel;
  StreamController<Uint8List>? _messageController;
  StreamController<bool>? _connectionStateController;
  StreamSubscription? _channelSubscription;
  String? _url;
  Timer? _reconnectTimer;

  @override
  Stream<Uint8List> get onMessage =>
      _messageController?.stream ?? Stream.empty();

  @override
  Stream<bool> get onConnectionStateChange =>
      _connectionStateController?.stream ?? Stream.empty();

  WebSocketChannelClient() {
    _messageController = StreamController<Uint8List>.broadcast();
    _connectionStateController = StreamController<bool>.broadcast();
  }

  @override
  Future<void> connect(String url) async {
    _url = url;
    await _attemptConnection();
  }

  Future<void> _attemptConnection() async {
    if (_reconnectTimer != null || _channel != null)
      return; // Already connecting or connected

    if (kDebugMode) {
      print('[WebSocketClient] Attempting to connect to $_url...');
    }
    _connectionStateController?.add(false);

    try {
      final uri = Uri.parse(_url!);
      _channel = WebSocketChannel.connect(uri);
      _connectionStateController?.add(true);

      if (kDebugMode) {
        print('[WebSocketClient] Connection established successfully.');
      }

      _channelSubscription = _channel!.stream.listen(
        (data) {
          if (data is Uint8List) {
            _messageController?.add(data);
          } else if (data is List<int>) {
            _messageController?.add(Uint8List.fromList(data));
          }
        },
        onDone: _handleDisconnect,
        onError: (error) {
          if (kDebugMode) {
            print('[WebSocketClient] Connection error: $error');
          }
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[WebSocketClient] Connection failed: $e');
      }
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (kDebugMode) {
      print('[WebSocketClient] Disconnected.');
    }
    _connectionStateController?.add(false);
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _channelSubscription = null;

    // Schedule a reconnect attempt
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      if (_url != null) {
        _attemptConnection();
      }
    });
  }

  @override
  void send(Uint8List data) {
    if (_channel != null && _channel!.sink != null) {
      _channel!.sink.add(data);
    }
  }

  @override
  void disconnect() {
    if (kDebugMode) {
      print('[WebSocketClient] Disconnecting permanently.');
    }
    _url = null; // Prevent reconnection
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    _connectionStateController?.close();
    _channel = null;
    _channelSubscription = null;
    _messageController = null;
    _connectionStateController = null;
  }
}
