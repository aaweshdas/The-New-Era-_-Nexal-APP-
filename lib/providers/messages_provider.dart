import 'dart:async';
import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ConversationModel {
  final String id;
  String name;
  String avatar;
  String lastMessage;
  String time;
  int unreadCount;
  bool isOnline;
  bool isGroup;

  ConversationModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Nexal User',
      avatar: json['avatar']?.toString() ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      lastMessage: json['lastMessage']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      unreadCount: (json['unreadCount'] as int?) ?? 0,
      isOnline: (json['isOnline'] as bool?) ?? false,
      isGroup: (json['isGroup'] as bool?) ?? false,
    );
  }
}

class MessagesProvider extends ChangeNotifier {
  // ── Curated fallback conversations (shown when backend is offline) ──
  final List<ConversationModel> _conversations = [
    ConversationModel(
      id: 'c1',
      name: 'Aria Storm',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      lastMessage: 'Sent a photo',
      time: '2m ago',
      unreadCount: 2,
      isOnline: true,
    ),
    ConversationModel(
      id: 'c2',
      name: 'Kai Cyber',
      avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100',
      lastMessage: 'Did you see the new quantum engine update? 🚀',
      time: '14m ago',
      isOnline: true,
    ),
    ConversationModel(
      id: 'c3',
      name: 'Nova Glitch',
      avatar: 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=100',
      lastMessage: "Let's meet at the digital plaza tonight.",
      time: '1h ago',
    ),
    ConversationModel(
      id: 'c4',
      name: 'Echo Vibe',
      avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100',
      lastMessage: 'Listening to Deep Space Mix 🎵',
      time: '5h ago',
      isOnline: true,
    ),
    ConversationModel(
      id: 'g1',
      name: 'Quantum Dev Syndicate',
      avatar: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=100',
      lastMessage: 'Nova: Build 2.4 released!',
      time: '1h ago',
      isGroup: true,
    ),
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);

  StreamSubscription? _messageSubscription;

  MessagesProvider() {
    _listenToSocket();
    fetchConversations();
  }

  void _listenToSocket() {
    _messageSubscription = SocketService.instance.onMessageReceived.listen((data) {
      final senderId = data['senderId'] as String?;
      final text = data['text'] as String?;
      if (senderId != null && text != null) {
        receiveMessage(senderId, text);
      }
    });
  }

  /// Connect Socket.IO for this user (called after login)
  void connectSocket(String userId) {
    SocketService.instance.connect(userId);
  }

  /// Fetch real conversations from the backend.
  /// Falls back gracefully to the curated list if unavailable.
  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.instance.get('/api/messages/conversations');
      if (res is List && res.isNotEmpty) {
        _conversations.clear();
        for (final item in res) {
          if (item is Map<String, dynamic>) {
            _conversations.add(ConversationModel.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Backend unavailable — curated fallback list already present
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void receiveMessage(String conversationId, String text) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index].lastMessage = text;
      _conversations[index].time = 'Just now';
      _conversations[index].unreadCount++;
    } else {
      _conversations.insert(
        0,
        ConversationModel(
          id: conversationId,
          name: 'Nexal Explorer',
          avatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
          lastMessage: text,
          time: 'Just now',
          unreadCount: 1,
          isOnline: true,
        ),
      );
    }
    notifyListeners();
  }

  void markConversationAsRead(String id) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      _conversations[index].unreadCount = 0;
      notifyListeners();
    }
  }

  void updateLastMessage(String conversationId, String text) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index].lastMessage = text;
      _conversations[index].time = 'Just now';
      notifyListeners();
    }
  }

  void addGroupConversation(String title, String avatar, List<String> members) {
    _conversations.insert(
      0,
      ConversationModel(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        name: title,
        avatar: avatar,
        lastMessage: 'Group created',
        time: 'Just now',
        isGroup: true,
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
