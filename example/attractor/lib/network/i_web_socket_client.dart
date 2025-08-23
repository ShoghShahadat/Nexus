// ==============================================================================
// File: lib/network/i_web_socket_client.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: An abstract interface for a WebSocket client.
// Changes:
// - CRITICAL FIX: The 'send' method's parameter type is changed from
//   'Uint8List' to 'dynamic'. This is essential for the new client-authoritative
//   model which sends Base64 strings, resolving the TypeError.
// ==============================================================================

import 'dart:async';
import 'dart:typed_data';

/// An abstract interface for a WebSocket client.
abstract class IWebSocketClient {
  /// A stream that emits data received from the server.
  Stream<Uint8List> get onMessage;

  /// A stream that emits connection status changes.
  Stream<bool> get onConnectionStateChange;

  /// Establishes a connection to the WebSocket server.
  Future<void> connect(String url);

  /// Sends data to the connected server.
  /// --- FIX: Changed parameter type to 'dynamic' ---
  void send(dynamic data);

  /// Closes the WebSocket connection.
  void disconnect();
}
