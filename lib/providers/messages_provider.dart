import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class ConversationModel {
  final String id;
  final String name;
  final String avatar;
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
}

class MessagesProvider extends ChangeNotifier {
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
      name: 'Quantum Dev Syndicate',
      avatar: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=100',
      lastMessage: 'Nova: Build 2.4 released!',
      time: '1h ago',
      isGroup: true,
    ),
  ];

  List<ConversationModel> get conversations => List.unmodifiable(_conversations);

  MessagesProvider() {
    SocketService.instance.onMessageReceived.listen((data) {
      final senderId = data['senderId'] as String?;
      final text = data['text'] as String?;
      if (senderId != null && text != null) {
        receiveMessage(senderId, text);
      }
    });
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
          avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
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
}
