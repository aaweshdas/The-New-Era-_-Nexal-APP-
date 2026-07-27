import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// Resolve & verify best working backend gateway URL (Render Cloud -> Saved -> Emulator / Localhost)
  static Future<String> resolveGatewayUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(_customGatewayKey);

      final candidates = <String>[
        if (customUrl != null && customUrl.isNotEmpty) customUrl,
        renderGatewayUrl,
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) devGatewayUrl else emulatorGatewayUrl,
        'http://localhost:10000',
      ];

      for (final url in candidates) {
        if (await _pingGateway(url)) {
          _resolvedGatewayUrl = url;
          debugPrint('[AppConfig] Gateway resolved & active: $url');
          return url;
        }
      }
    } catch (e) {
      debugPrint('[AppConfig] Gateway resolution notice: $e');
    }

    _resolvedGatewayUrl = defaultGatewayUrl;
    return defaultGatewayUrl;
  }

  static Future<bool> _pingGateway(String url) async {
    try {
      final uri = Uri.parse('$url/health');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 2500));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setCustomGatewayUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customGatewayKey, url);
    _resolvedGatewayUrl = url;
  }
}
