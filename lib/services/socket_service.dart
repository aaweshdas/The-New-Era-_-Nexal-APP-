import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTypingStateChanged => _typingController.stream;

  void connect(String userId) {
    if (_isConnected) return;
    try {
      _socket = io.io(
        AppConfig.apiBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('[SocketIO] Connected to ${AppConfig.apiBaseUrl}');
      });

      _socket?.on('message', (data) {
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        }
      });

      _socket?.on('typing', (data) {
        if (data is Map<String, dynamic>) {
          _typingController.add(data);
        }
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[SocketIO] Disconnected');
      });
    } catch (e) {
      debugPrint('[SocketIO Error] $e');
    }
  }

  void sendMessage(String recipientId, String text) {
    if (_socket != null && _isConnected) {
      _socket?.emit('message', {
        'recipientId': recipientId,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void sendTypingStatus(String recipientId, bool isTyping) {
    if (_socket != null && _isConnected) {
      _socket?.emit('typing', {
        'recipientId': recipientId,
        'isTyping': isTyping,
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }
}
