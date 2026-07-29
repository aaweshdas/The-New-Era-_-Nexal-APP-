import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      time: json['time']?.toString() ?? json['createdAt']?.toString() ?? 'Just now',
      iconType: json['iconType']?.toString() ?? 'system',
      isRead: (json['isRead'] as bool?) ?? false,
    );
  }
}

class NotificationsProvider extends ChangeNotifier {
  final List<NotificationItemModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationItemModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationsProvider() {
    fetchNotifications();
  }

  void reset() {
    _notifications.clear();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.instance.get('/api/notifications');
      if (res is List) {
        _notifications.clear();
        for (final item in res) {
          if (item is Map<String, dynamic>) {
            _notifications.add(NotificationItemModel.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Backend error or offline — leave notifications list empty
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
