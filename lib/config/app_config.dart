class AppConfig {
  static const String appName = 'Nexal';
  static const String appVersion = '1.0.0';

  // Environment-based Base URLs
  static const String devApiUrl = 'http://localhost:3004';
  static const String prodApiUrl = 'https://api.nexal.space';

  static String get apiBaseUrl {
    // Default to dev for local execution
    return devApiUrl;
  }
}
