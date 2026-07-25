import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Nexal';
  static const String appVersion = '1.0.0';

  // Gateway Base URLs (Unified port 10000)
  // For Android Emulator: http://10.0.2.2:10000
  // For Local Desktop / Web: http://localhost:10000
  static const String devGatewayUrl = 'http://localhost:10000';
  static const String emulatorGatewayUrl = 'http://10.0.2.2:10000';
  static const String prodGatewayUrl = 'https://api.nexal.space';

  static String get gatewayUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      return devGatewayUrl;
    }
    // Android / iOS physical/emulator
    return emulatorGatewayUrl;
  }

  static String get apiBaseUrl => gatewayUrl;
  static String get ariaBackendUrl => gatewayUrl;
}
