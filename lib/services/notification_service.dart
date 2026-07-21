import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  Future<void> init() async {
    debugPrint('[NotificationService] Initializing Push Notification Handlers...');
  }

  void showLocalNotification(String title, String body) {
    debugPrint('[Push Notification] $title : $body');
  }

  Future<String?> getFCMToken() async {
    return 'fcm_token_sample_${DateTime.now().millisecondsSinceEpoch}';
  }
}
