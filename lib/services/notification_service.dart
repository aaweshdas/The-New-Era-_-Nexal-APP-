import 'dart:async';
import 'package:flutter/foundation.dart';

class PushNotificationEvent {
  final String title;
  final String body;
  final DateTime timestamp;

  PushNotificationEvent({
    required this.title,
    required this.body,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _notificationStreamCtrl = StreamController<PushNotificationEvent>.broadcast();
  Stream<PushNotificationEvent> get onNotificationReceived => _notificationStreamCtrl.stream;

  Future<void> init() async {
    debugPrint('[NotificationService] Initializing Push Notification Handlers...');
  }

  void showLocalNotification(String title, String body) {
    debugPrint('[Push Notification] $title : $body');
    _notificationStreamCtrl.add(PushNotificationEvent(title: title, body: body));
  }

  Future<String?> getFCMToken() async {
    return 'fcm_token_sample_${DateTime.now().millisecondsSinceEpoch}';
  }
}
