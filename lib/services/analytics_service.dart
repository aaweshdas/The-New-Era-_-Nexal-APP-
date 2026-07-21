import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  AnalyticsService._internal();

  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    debugPrint('[Analytics Event] $name : ${parameters ?? {}}');
  }

  void logScreen(String screenName) {
    debugPrint('[Analytics Screen] $screenName');
  }

  void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('[Analytics Error] $error\n$stackTrace');
  }
}
