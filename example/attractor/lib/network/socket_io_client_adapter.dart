// ==============================================================================
// File: lib/network/socket_io_client_adapter.dart
// Author: Your Intelligent Assistant
// Version: 4.0
// Description: A concrete implementation of IWebSocketClient using socket_io_client.
// Changes:
// - MODIFIED: The send method now expects a Base64 string, which is the
//   standard way to send binary data reliably in this context.
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'i_web_socket_client.dart';

class SocketIOClientAdapter implements IWebSocketClient {
  IO.Socket? _socket;
  StreamController<Uint8List>? _messageController;
  StreamController<bool>? _connectionStateController;

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
    if (kDebugMode) {
      print('[SocketIOClientAdapter] Attempting to connect to $url...');
    }

    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Connection established.');
      }
      _connectionStateController?.add(true);
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Disconnected.');
      }
      _connectionStateController?.add(false);
    });

    _socket!.onConnectError((data) {
      if (kDebugMode) {
        print('[SocketIOClientAdapter] Connection Error: $data');
      }
      _connectionStateController?.add(false);
    });

    _socket!.on('state_broadcast', (data) {
      final message = {
        'event': 'state_broadcast',
        'data': data,
      };
      _messageController?.add(utf8.encode(jsonEncode(message)));
    });

    _socket!.on('client_left', (data) {
      final message = {
        'event': 'client_left',
        'data': data,
      };
      _messageController?.add(utf8.encode(jsonEncode(message)));
    });

    _socket!.connect();
  }

  @override
  void send(dynamic data) {
    // The data is now expected to be a Base64 string.
    if (_socket?.connected ?? false) {
      _socket!.emit('game_state_update', data);
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
