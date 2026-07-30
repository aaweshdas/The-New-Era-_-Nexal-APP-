import 'dart:async';
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _userId;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTypingStateChanged => _typingController.stream;

  void connect(String userId) {
    _userId = userId;
    _isConnected = true;
    debugPrint('[SocketService] Local socket engine connected for user $userId');
  }

  void sendMessage(String recipientId, String text) {
    final msg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': _userId ?? 'me',
      'recipientId': recipientId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _messageController.add(msg);
  }

  void sendTypingStatus(String recipientId, bool isTyping) {
    _typingController.add({
      'recipientId': recipientId,
      'isTyping': isTyping,
    });
  }

  void disconnect({bool isReconnect = false}) {
    _isConnected = false;
    if (!isReconnect) {
      _userId = null;
    }
  }
}
