import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ConversationModel {
  final String id;
  final String userId;
  String name;
  String username;
  String avatar;
  String lastMessage;
  String time;
  int unreadCount;
  bool isOnline;
  bool isGroup;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.name,
    this.username = '',
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? 'Nexal User',
      username: json['username']?.toString() ?? '',
      avatar: json['avatarUrl']?.toString() ?? json['avatar']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      time: json['time']?.toString() ?? json['lastMessageTime']?.toString() ?? '',
      unreadCount: (json['unreadCount'] as int?) ?? 0,
      isOnline: (json['isOnline'] as bool?) ?? false,
      isGroup: (json['isGroup'] as bool?) ?? false,
    );
  }
}

class MessagesProvider extends ChangeNotifier {
  final List<ConversationModel> _conversations = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);

  StreamSubscription? _messageSubscription;

  MessagesProvider() {
    _listenToSocket();
    fetchConversations();
  }

  void reset() {
    _conversations.clear();
    _isLoading = false;
    notifyListeners();
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

  void connectSocket(String userId) {
    SocketService.instance.connect(userId);
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.instance.get('/api/messages/conversations');
      if (res is List) {
        _conversations.clear();
        for (final item in res) {
          if (item is Map<String, dynamic>) {
            _conversations.add(ConversationModel.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Backend error or offline — keep conversations state clean
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> receiveMessage(String senderId, String text) async {
    final index = _conversations.indexWhere((c) => c.userId == senderId || c.id == senderId);
    if (index != -1) {
      _conversations[index].lastMessage = text;
      _conversations[index].time = 'Just now';
      _conversations[index].unreadCount++;
      notifyListeners();
    } else {
      // Fetch sender profile dynamically from Supabase
      String senderName = 'Nexal User';
      String senderAvatar = '';
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name, username, avatar_url')
            .eq('id', senderId)
            .maybeSingle();
        if (profile != null) {
          senderName = profile['name'] ?? profile['username'] ?? 'Nexal User';
          senderAvatar = profile['avatar_url'] ?? '';
        }
      } catch (_) {}

      _conversations.insert(
        0,
        ConversationModel(
          id: senderId,
          userId: senderId,
          name: senderName,
          avatar: senderAvatar,
          lastMessage: text,
          time: 'Just now',
          unreadCount: 1,
          isOnline: true,
        ),
      );
      notifyListeners();
    }
  }

  void markConversationAsRead(String id) {
    final index = _conversations.indexWhere((c) => c.id == id || c.userId == id);
    if (index != -1) {
      _conversations[index].unreadCount = 0;
      notifyListeners();
    }
  }

  void updateLastMessage(String conversationId, String text) {
    final index = _conversations.indexWhere((c) => c.id == conversationId || c.userId == conversationId);
    if (index != -1) {
      _conversations[index].lastMessage = text;
      _conversations[index].time = 'Just now';
      notifyListeners();
    }
  }

  void addGroupConversation(String title, String avatar, List<String> members) {
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';
    _conversations.insert(
      0,
      ConversationModel(
        id: id,
        userId: id,
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
