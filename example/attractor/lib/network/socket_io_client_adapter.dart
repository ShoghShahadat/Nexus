import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'i_web_socket_client.dart';

/// A concrete implementation of [IWebSocketClient] using the `socket_io_client` package.
/// This adapter translates Socket.IO events into the simple stream-based interface our app uses.
/// یک پیاده‌سازی مشخص از [IWebSocketClient] با استفاده از پکیج `socket_io_client`.
/// این آداپتور رویدادهای Socket.IO را به اینترفیس مبتنی بر استریم که برنامه ما استفاده می‌کند، ترجمه می‌کند.
class SocketIOClientAdapter implements IWebSocketClient {
  IO.Socket? _socket;
  StreamController<Uint8List>? _messageController;
  StreamController<bool>? _connectionStateController;
  String? _url;

  @override
  Stream<Uint8List> get onMessage =>
      _messageController?.stream ?? Stream.empty();

  @override
  Stream<bool> get onConnectionStateChange =>
      _connectionStateController?.stream ?? Stream.empty();

  SocketIOClientAdapter() {
    _messageController = StreamController<Uint8List>.broadcast();
    _connectionStateController = StreamController<bool>.broadcast();
  }

  @override
  Future<void> connect(String url) async {
    _url = url;
    if (kDebugMode) {
      print('[SocketIOClientAdapter] Attempting to connect to $_url...');
    }

    // Configure the Socket.IO client.
    // We explicitly use WebSocket transport and disable auto-connection.
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // --- Setup Event Listeners ---
    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Connection established successfully.');
      }
      _connectionStateController?.add(true);
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Disconnected.');
      }
      _connectionStateController?.add(false);
      // The library handles reconnection logic automatically.
    });

    _socket!.onConnectError((data) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Connection Error: $data');
      }
      _connectionStateController?.add(false);
    });

    _socket!.onError((data) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Generic Error: $data');
      }
    });

    // Listen for the 'message' event from the Python server.
    _socket!.on('message', (data) {
      if (data is List<int>) {
        _messageController?.add(Uint8List.fromList(data));
      } else if (data is Uint8List) {
        _messageController?.add(data);
      }
    });

    // Manually initiate the connection.
    _socket!.connect();
  }

  @override
  void send(Uint8List data) {
    if (_socket?.connected ?? false) {
      // Emit data on the 'message' event to the Python server.
      _socket!.emit('message', data);
    }
  }

  @override
  void disconnect() {
    if (kDebugMode) {
      print('[SocketIOClientAdapter] Disconnecting permanently.');
    }
    _socket?.dispose();
    _messageController?.close();
    _connectionStateController?.close();
  }
}
