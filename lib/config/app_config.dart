import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appName = 'Nexal';
  static const String appVersion = '1.0.0';

  // Gateway Base URLs
  static const String renderGatewayUrl = 'https://nexal-backend.onrender.com';
  static const String devGatewayUrl = 'http://localhost:10000';
  static const String emulatorGatewayUrl = 'http://10.0.2.2:10000';
  static const String prodGatewayUrl = 'https://nexal-backend.onrender.com';

  static const String _customGatewayKey = 'custom_gateway_url';
  static String? _resolvedGatewayUrl;

  /// Default gateway URL (Render Cloud Gateway for live production)
  static String get defaultGatewayUrl => renderGatewayUrl;

  static String get gatewayUrl => _resolvedGatewayUrl ?? defaultGatewayUrl;
  static String get apiBaseUrl => gatewayUrl;
  static String get ariaBackendUrl => gatewayUrl;

  /// Resolve gateway URL (returns default offline gateway URL without network delay)
  static Future<String> resolveGatewayUrl() async {
    _resolvedGatewayUrl = defaultGatewayUrl;
    debugPrint('[AppConfig] Using standalone client mode: $defaultGatewayUrl');
    return defaultGatewayUrl;
  }

  static Future<void> setCustomGatewayUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customGatewayKey, url);
    _resolvedGatewayUrl = url;
  }
}
