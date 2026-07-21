import 'package:flutter/material.dart';

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String time;
  final String iconType;
  bool isRead;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.iconType,
    this.isRead = false,
  });
}

class NotificationsProvider extends ChangeNotifier {
  final List<NotificationItemModel> _notifications = [
    NotificationItemModel(
      id: 'n1',
      title: 'Aria Storm liked your post',
      body: '"Witnessing the future unfold in real-time ✨"',
      time: '5m ago',
      iconType: 'like',
    ),
    NotificationItemModel(
      id: 'n2',
      title: 'New connection request',
      body: 'Kai Cyber wants to connect with you.',
      time: '20m ago',
      iconType: 'user',
    ),
    NotificationItemModel(
      id: 'n3',
      title: 'Quantum Engine Update Live',
      body: 'Version 2.4 is now available across all sectors.',
      time: '1h ago',
      iconType: 'system',
    ),
  ];

  List<NotificationItemModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void addNotification(NotificationItemModel item) {
    _notifications.insert(0, item);
    notifyListeners();
  }
}
